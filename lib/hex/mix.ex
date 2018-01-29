defmodule Hex.Mix do
  @moduledoc """
  Utility functions around Mix dependencies.
  """

  @type dep :: {String.t(), String.t(), boolean, [String.t()]}

  @doc """
  Returns `true` if the version and requirement match.

  See `Version.match?/2`.
  """
  @spec version_match?(String.t(), String.t() | nil) :: boolean
  def version_match?(_version, nil), do: true
  def version_match?(version, req), do: Hex.Version.match?(version, req)

  @doc """
  Given a tree of dependencies return a flat list of all dependencies in
  the tree.

  The returned flattened list is going to contain duplicated dependencies
  because we want to accumulate all of the different requirements.
  However we must skip overridden dependencies as their requirements
  are no longer relevant. We also skip dependencies that are not included
  in the original list of dependencies as they were likely filtered out
  due to options like `:only`.
  """
  @spec flatten_deps([Mix.Dep.t()], [atom]) :: [Mix.Dep.t()]
  def flatten_deps(deps, top_level) do
    apps = Enum.map(deps, & &1.app)
    top_level = Enum.map(top_level, &Atom.to_string/1)
    prepared_deps = prepare_deps(deps)

    deps ++
      for(
        dep <- deps,
        overridden_map = overridden_parents(top_level, prepared_deps, Atom.to_string(dep.app)),
        %{app: app} = child <- dep.deps,
        app in apps and !overridden_map[Atom.to_string(app)],
        do: child
      )
  end

  @doc """
  Returns a map with the overridden upper breadths dependencies of
  the given parent (including the parent level itself).
  """
  @spec overridden_parents([String.t()], [dep], String.t()) :: [dep]
  def overridden_parents(top_level, deps, parent) do
    deps
    |> Enum.filter(fn {_repo, app, _override, _children} -> app in top_level end)
    |> do_overridden_parents(deps, parent, %{})
    |> elem(0)
  end

  def do_overridden_parents(level, deps, parent, visited) do
    {children_map, found?, visited} =
      Enum.reduce(level, {%{}, false, visited}, fn {_repo, app, _override, children},
                                                   {acc_map, acc_found?, visited} ->
        case Map.fetch(visited, app) do
          {:ok, {children_map, found?}} ->
            {Map.merge(acc_map, children_map), found? or acc_found?, visited}

          :error ->
            children_apps = Enum.map(children, &elem(&1, 1))
            children_deps = Enum.filter(deps, fn {_, app, _, _} -> app in children_apps end)

            {children_map, found?, visited} =
              do_overridden_parents(children_deps, deps, parent, visited)

            visited = Map.put(visited, app, {children_map, found?})
            {Map.merge(acc_map, children_map), found? or acc_found?, visited}
        end
      end)

    cond do
      found? ->
        overridden_map = Map.merge(level_to_overridden_map(level), children_map)
        {overridden_map, true, visited}

      parent in Enum.map(level, &elem(&1, 1)) ->
        {level_to_overridden_map(level), true, visited}

      true ->
        {%{}, false, visited}
    end
  end

  defp level_to_overridden_map(level) do
    for {_repo, app, override, _children} <- level,
        override,
        do: {app, true},
        into: %{}
  end

  @doc """
  Add a potentially new dependency and its children.
  This function is used to add Hex packages to the dependency tree which
  we use in overridden_parents to check overridden status.
  """
  def attach_dep_and_children(deps, app, children) do
    {repo, app, override, _} = Enum.find(deps, &(elem(&1, 1) == app))

    children =
      Enum.map(children, fn {repo, _name, app, _req, _optional} ->
        {repo, app, false, []}
      end)

    new_dep = {repo, app, override, children}
    put_dep(deps, new_dep) ++ children
  end

  # Replace a dependency in the tree
  defp put_dep(deps, {_, new_app, _, _} = new_dep) do
    Enum.map(deps, fn {_, app, _, _} = dep ->
      if app == new_app, do: new_dep, else: dep
    end)
  end

  @doc """
  Converts a list of dependencies to a requests to the resolver. Skips
  dependencies overriding with another SCM (but include dependencies
  overriding with Hex) and dependencies that are not Hex packages.
  """
  def deps_to_requests(deps) do
    requests =
      for %Mix.Dep{app: app, requirement: req, scm: Hex.SCM, opts: opts, from: from} <- deps do
        from = Path.relative_to_cwd(from)
        {opts[:repo], opts[:hex], Atom.to_string(app), req, from}
      end

    # Elixir < 1.3.0-dev returned deps in reverse order
    if Version.compare(System.version(), "1.3.0-dev") == :lt do
      Enum.reverse(requests)
    else
      requests
    end
  end

  @doc """
  Prepare Mix dependencies for the format the resolver expects.
  """
  @spec prepare_deps([Mix.Dep.t()]) :: [dep]
  def prepare_deps(deps) do
    Enum.map(deps, fn %Mix.Dep{app: app, deps: deps, opts: opts} ->
      deps =
        Enum.map(deps, fn %Mix.Dep{app: app, opts: opts} ->
          {opts[:repo] || "hexpm", Atom.to_string(app), !!opts[:override], []}
        end)

      {opts[:repo] || "hexpm", Atom.to_string(app), !!opts[:override], deps}
    end)
  end

  @doc """
  Returns all top level dependencies.
  """
  @spec top_level([Mix.Dep.t()]) :: [atom]
  def top_level(deps) do
    deps
    |> Enum.filter(& &1.top_level)
    |> Enum.map(& &1.app)
  end

  @doc """
  Normalises a dependency definition to its 3-tuple form.
  """
  @spec dep(tuple) :: {String.t(), String.t(), Keyword.t()}
  def dep({app, opts}) when is_list(opts), do: {app, nil, opts}
  def dep({app, req}) when is_binary(req), do: {app, req, []}
  def dep({app, req, opts}), do: {app, req, opts}

  @doc """
  Takes all Hex packages from the lock and returns them
  as `{name, app, version, repo}` tuples.
  """
  @spec from_lock(%{}) :: [{String.t(), String.t(), String.t(), String.t()}]
  def from_lock(lock) do
    Enum.flat_map(lock, fn {app, info} ->
      case Hex.Utils.lock(info) do
        %{name: name, version: version, repo: repo} ->
          [{repo, name, Atom.to_string(app), version}]

        nil ->
          []
      end
    end)
  end

  @doc """
  Takes a map of `{name, version}` and returns them as a
  lock of Hex packages.
  """
  def to_lock(result) do
    Enum.into(result, %{}, fn {repo, name, app, version} ->
      checksum =
        Hex.Registry.Server.checksum(repo, name, version)
        |> Base.encode16(case: :lower)

      deps =
        Hex.Registry.Server.deps(repo, name, version)
        |> Enum.map(&registry_dep_to_def/1)
        |> Enum.sort()

      managers =
        managers(app)
        |> Enum.sort()
        |> Enum.uniq()

      {String.to_atom(app), {:hex, String.to_atom(name), version, checksum, managers, deps, repo}}
    end)
  end

  # We need to get managers from manifest if a dependency is not in the lock
  # but it's already fetched. Without the manifest we would only get managers
  # from metadata during checkout or from the lock entry.
  defp managers(nil), do: []

  defp managers(app) do
    path = Path.join([Mix.Project.deps_path(), app, ".hex"])

    case File.read(path) do
      {:ok, file} ->
        case Hex.SCM.parse_manifest(file) do
          [_name, _version, _checksum, managers | _] -> managers
          _ -> []
        end

      _ ->
        []
    end
  end

  defp registry_dep_to_def({repo, name, app, req, optional}) do
    {String.to_atom(app), req, hex: String.to_atom(name), repo: repo, optional: optional}
  end

  def packages_from_lock(lock) do
    Enum.flat_map(lock, fn {_app, info} ->
      case Hex.Utils.lock(info) do
        %{name: name, repo: repo} ->
          [{repo, name}]

        nil ->
          []
      end
    end)
  end
end
