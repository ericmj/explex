defmodule Mix.Tasks.Hex.Registry do
  use Mix.Task

  @shortdoc "Manages the local Hex registry"

  @moduledoc """
  Tasks for working with the locally cached registry file.

  ### Fetch registry

  Updates the locally cached registry file.

  `mix hex.registry fetch`

  ### Dump registry

  Copies the cached registry file to the given path.

  `mix hex.registry dump <path>`

  ### Load registry

  Copies given regsitry file to the cache.

  `mix hex.registry load <path>`
  """

  def run(args) do
    Hex.start

    case args do
      ["fetch"] ->
        fetch()
      ["dump", path] ->
        dump(path)
      ["load", path] ->
        load(path)
      _otherwise ->
        message = """
          Invalid arguments, expected one of:
            mix hex.registry fetch
            mix hex.registry dump <path>
            mix hex.registry load <path>
          """
        Mix.raise message
    end
  end

  defp fetch() do
    Hex.Utils.ensure_registry!(update: true)
  end

  defp dump(dest) do
    path_gz = Hex.Registry.ETS.path <> ".gz"
    File.cp!(path_gz, dest)
  end

  defp load(source) do
    path = Hex.Registry.ETS.path
    path_gz = path <> ".gz"
    content = File.read!(source) |> :zlib.gunzip
    File.cp!(source, path_gz)
    File.write!(path, content)
  end
end
