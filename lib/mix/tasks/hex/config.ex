defmodule Mix.Tasks.Hex.Config do
  use Mix.Task

  @shortdoc "Read or update hex config"

  @moduledoc """
  Reads or updates hex configuration file.

  `mix hex.config key [value]`
  """

  def run(args) do
    case args do
      [key] ->
        case Keyword.fetch(Hex.Mix.read_config, :"#{key}") do
          { :ok, value } -> Mix.shell.info(inspect(value, pretty: true))
          :error         -> raise Mix.Error, message: "Config does not contain a key #{key}"
        end
      [key, value] ->
        Hex.Mix.update_config([{ :"#{key}", value }])
      _ ->
        raise Mix.Error, message: "Invalid arguments, expected 'mix hex.config key [value]'"
    end
  end
end
