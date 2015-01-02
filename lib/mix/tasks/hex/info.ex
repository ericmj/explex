defmodule Mix.Tasks.Hex.Info do
  use Mix.Task
  alias Mix.Tasks.Hex.Util

  @shortdoc "Print hex information"

  @moduledoc """
  Prints hex package or system information.

  `mix hex.info [PACKAGE [VERSION]]`

  If `package` is not given, print system information. This includes when
  registry was last updated and current system version.

  If `package` is given, print information about the package. This includes all
  released versions and package metadata.

  If `package` and `version` is given print release information. This includes
  remote Git URL and Git ref, and all package dependencies.
  """

  def run(args) do
    spinner = Util.start_spinner

    {_opts, args, _} = OptionParser.parse(args)
    Hex.start
    Hex.Util.ensure_registry(cache: false)

    Util.stop_spinner(spinner)

    case args do
      [] -> general()
      [package] -> package(package)
      [package, version] -> release(package, version)
      _ ->
        Mix.raise "Invalid arguments, expected: mix hex.info [PACKAGE [VERSION]]"
    end
  end

  defp general() do
    Mix.shell.info("Hex v" <> Hex.version)
    line_break()

    Mix.shell.info("Hex is a package manager for the Erlang ecosystem.")
    Mix.shell.info("This is a basic help message containing pointers to more information.")
    line_break()

    path = Hex.Registry.path()
    stat = File.stat!(path)
    {packages, releases} = Hex.Registry.stat()

    Mix.shell.info("Registry file available (last updated: #{pretty_date(stat.mtime)})")
    Mix.shell.info("Size: #{div stat.size, 1024}kB")
    Mix.shell.info("Packages #: #{packages}")
    Mix.shell.info("Versions #: #{releases}")

    if Version.match?(System.version, ">= 1.1.0-dev") do
      line_break()
      Mix.shell.info("Available tasks:")
      line_break()
      Mix.Task.run("help", ["--search", "hex."])
    end

    line_break()
    Mix.shell.info("Further information can be found here: https://hex.pm/docs/tasks")
  end

  defp package(package) do
    case Hex.API.Package.get(package) do
      {code, body} when code in 200..299 ->
        pretty_package(body)
      {404, _} ->
        Mix.shell.error("No package with name #{package}")
      {code, body} ->
        Mix.shell.error("Failed to retrieve package information")
        Hex.Util.print_http_code(code)
        Hex.Util.print_error_result(code, body)
    end
  end

  defp release(package, version) do
    case Hex.API.Release.get(package, version) do
      {code, body} when code in 200..299 ->
        pretty_release(package, body)
      {404, _} ->
        Mix.shell.error("No release with name #{package} v#{version}")
      {code, body} ->
        Mix.shell.error("Failed to retrieve release information")
        Hex.Util.print_http_code(code)
        Hex.Util.print_error_result(code, body)
    end
  end

  defp pretty_package(package) do
    Mix.shell.info(package["name"])
    Mix.shell.info("  Releases: " <> Enum.map_join(package["releases"], ", ", &(&1["version"])))
    line_break()
    pretty_meta(package["meta"])
  end

  defp pretty_meta(meta) do
    pretty_list(meta, "contributors")
    pretty_list(meta, "licenses")
    pretty_dict(meta, "links")

    if descr = meta["description"] do
      line_break()
      Mix.shell.info(descr)
    end
  end

  defp pretty_release(package, release) do
    version = release["version"]
    Mix.shell.info(package <> " v" <> version)

    if release["has_docs"] do
      Mix.shell.info("  Documentation at: #{Hex.Util.hexdocs_url(package, version)}")
    end

    if release["requirements"] do
      Mix.shell.info("  Dependencies:")
      Enum.each(release["requirements"], fn {name, req} ->
        if req["optional"] do
          optional = " (optional)"
        end
        Mix.shell.info("    #{name}: #{req["requirement"]}#{optional}")
      end)
    end
  end

  defp pretty_list(meta, name) do
    if (list = meta[name]) && list != [] do
      Mix.shell.info("  #{String.capitalize(name)}: " <> Enum.join(list, ", "))
    end
  end

  defp pretty_dict(meta, name, title \\ nil) do
    title = title || String.capitalize(name)

    if (dict = meta[name]) && dict != [] do
      Mix.shell.info("  #{title}:")
      Enum.each(dict, fn {name, url} ->
        Mix.shell.info("    #{name}: #{url}")
      end)
    end
  end

  defp pretty_date({{year, month, day}, {hour, min, sec}}) do
    "#{pad(year, 4)}-#{pad(month, 2)}-#{pad(day, 2)} " <>
    "#{pad(hour, 2)}:#{pad(min, 2)}:#{pad(sec, 2)}"
  end

  defp pad(int, padding) do
    str = to_string(int)
    padding = max(padding-byte_size(str), 0)
    do_pad(str, padding)
  end

  defp do_pad(str, 0), do: str
  defp do_pad(str, n), do: do_pad("0" <> str, n-1)

  defp line_break(), do: Mix.shell.info("")
end
