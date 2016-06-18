defmodule Mix.Tasks.Hex.Key do
  use Mix.Task
  alias Mix.Hex.Utils

  @shortdoc "Manages Hex API key"

  @moduledoc """
  Removes or lists API keys associated with your account.

  ### Remove key

  Removes given API key from account.

  The key can no longer be used to authenticate API requests.

  `mix hex.key remove key_name`

  ### List keys

  Lists all API keys associated with your account.

  `mix hex.key list`
  """

  def run(args) do
    Hex.start
    Hex.Utils.ensure_registry(fetch: false)

    auth = Utils.auth_info()

    case args do
      ["remove", key] ->
        remove_key(key, auth)
      ["list"] ->
        list_keys(auth)
      _ ->
        Mix.raise "Invalid arguments, expected one of:\nmix hex.key remove KEY\nmix hex.key list"
    end
  end

  defp remove_key(key, auth) do
    Hex.Shell.info "Removing key #{key}..."
    case Hex.API.Key.delete(key, auth) do
      {code, _body, _headers} when code in 200..299 ->
        :ok
      {code, body, _headers} ->
        Hex.Shell.error "Key fetching failed"
        Hex.Utils.print_error_result(code, body)
    end
  end

  defp list_keys(auth) do
    case Hex.API.Key.get(auth) do
      {code, body, _headers} when code in 200..299 ->
        Enum.each(body, &Hex.Shell.info(&1["name"]))
      {code, body, _headers} ->
        Hex.Shell.error "Key fetching failed"
        Hex.Utils.print_error_result(code, body)
    end
  end
end
