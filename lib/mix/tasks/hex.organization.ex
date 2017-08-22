defmodule Mix.Tasks.Hex.Organization do
  use Mix.Task

  @shortdoc "Manages Hex.pm organizations"

  @moduledoc """
  Manages the list of authorized Hex.pm organizations.

  Organizations is a feature of Hex.pm to host and manage private packages. See
  https://hex.pm/docs/private for more information.

  By authorizing a new organization a new key is created for fetching packages
  from the organizations repository and the repository and key is stored on the
  local machine.

  To use a package from an organization add `organization: "my_organization"` to the
  dependency declaration in `mix.exs`:

      {:plug, "~> 1.0", repo: "my_organization"}

  ## Authorize an organization

      mix hex.organization auth NAME

  ## Deauthorize and remove an organization

      mix hex.organization deauth NAME

  ## List all authorized organizations

      mix hex.organization list
  """

  def run(args) do
    Hex.start()

    case args do
      ["auth", name] ->
        auth(name)
      ["deauth", name] ->
        deauth(name)
      ["list"] ->
        list()
      _ ->
        Mix.raise """
        Invalid arguments, expected one of:

        mix hex.organization auth NAME
        mix hex.organization deauth NAME
        mix hex.organization list
        """
    end
  end

  def auth(name) do
    hexpm = Hex.Repo.get_repo("hexpm")
    repo = %{
      url: hexpm.url <> "/repos/#{name}",
      public_key: nil,
      auth_key: generate_repo_key(name),
    }

    read_config()
    |> Map.put("hexpm:#{name}", repo)
    |> Hex.Config.update_repos()
  end

  defp deauth(name) do
    read_config()
    |> Map.delete("hexpm:#{name}")
    |> Hex.Config.update_repos()
  end

  defp list() do
    Enum.each(read_config(), fn {name, _repo} ->
      case String.split(name, ":", parts: 2) do
        ["hexpm", name] ->
          Hex.Shell.info(name)
        _ ->
          :ok
      end
    end)
  end

  defp read_config() do
    Hex.Config.read()
    |> Hex.Config.read_repos()
  end

  defp generate_repo_key(name) do
    auth = Mix.Tasks.Hex.auth_info()
    permissions = [%{"domain" => "repository", "resource" => name}]

    {:ok, host} = :inet.gethostname()
    key = "#{host}-repository"

    case Hex.API.Key.new(key, permissions, auth) do
      {:ok, {201, body, _}} ->
        body["secret"]
      other ->
        Hex.Utils.print_error_result(other)
        Mix.raise "Generation of repository key failed"
    end
  end
end
