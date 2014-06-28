defmodule Mix.Tasks.Hex.Owner do
  use Mix.Task
  alias Mix.Tasks.Hex.Util

  @shortdoc "Hex package ownership tasks"

  @moduledoc """
  Add, remove or list package owners.

  A package owner have full permissions to the package. They can publish and
  revert releases and even remove other package owners.

  ### Add owner

  Add an owner to package by specifying the package name and email of the new
  owner.

  `mix hex.owner add PACKAGE EMAIL`

  ### Remove owner

  Remove an owner to package by specifying the package name and email of the new
  owner.

  `mix hex.owner remove PACKAGE EMAIL`

  ### List owners

  List all owners of given package.

  `mix hex.owner list PACKAGE`

  ## Command line options

  * `--user`, `-u` - Username of existing package owner (overrides user stored in config)

  * `--pass`, `-p` - Password of existing package owner (required if `--user` was given)
  """

  @aliases [u: :user, p: :pass]

  def run(args) do
    {opts, rest, _} = OptionParser.parse(args, aliases: @aliases)
    user_config       = Hex.Mix.read_config
    auth              = Util.auth_opts(opts, user_config)
    Hex.start_api

    case rest do
      ["add", package, owner] ->
        add_owner(package, owner, auth)
      ["remove", package, owner] ->
        remove_owner(package, owner, auth)
      ["list", package] ->
        list_owners(package, auth)
      _ ->
        Mix.raise "Invalid arguments, expected 'mix hex.owner TASK ...'"
    end
  end

  defp add_owner(package, owner, opts) do
    Mix.shell.info("Adding owner #{owner} to #{package}")
    case Hex.API.add_package_owner(package, owner, opts) do
      {204, _body} ->
        :ok
      {code, body} ->
        Mix.shell.error("Adding owner failed (#{code})")
        Hex.Util.print_error_result(code, body)
    end
  end

  defp remove_owner(package, owner, opts) do
    Mix.shell.info("Removing owner #{owner} from #{package}")
    case Hex.API.delete_package_owner(package, owner, opts) do
      {204, _body} ->
        :ok
      {code, body} ->
        Mix.shell.error("Removing owner failed (#{code})")
        Hex.Util.print_error_result(code, body)
    end
  end

  defp list_owners(package, opts) do
    case Hex.API.get_package_owners(package, opts) do
      {200, body} ->
        Enum.each(body, &Mix.shell.info(&1["email"]))
      {code, body} ->
        Mix.shell.error("Package owner fetching failed (#{code})")
        Hex.Util.print_error_result(code, body)
    end
  end
end
