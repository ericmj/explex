defmodule Mix.Tasks.Hex do
  use Mix.Task

  @apikey_tag "HEXAPIKEY"

  @shortdoc "Prints Hex help information"

  @moduledoc """
  Prints Hex tasks and their information.

  `mix hex`

  Hex and some Mix tasks can be configured with the following environment
  variables:

    * `HEX_HOME` - Sets the directory where Hex stores the cache and
      configuration (Default: `~/.hex`)
    * `HEX_API` - Sets the API URL (Default: `https://hex.pm/api`)
    * `HEX_OFFLINE` - If set Hex will not fetch the registry or packages and will
      instead the locally cached files if they are available
    * `HEX_UNSAFE_HTTPS` - If set Hex will not verify HTTPS certificates
    * `HEX_UNSAFE_REGISTRY` - If set Hex will not verify the registry signature
      against the repository's public key
    * `HTTP_PROXY` / `HTTPS_PROXY` - Sets the URL to a HTTP(S) proxy, the
      environment variables can also be in lower case
    * `HEX_HTTP_CONCURRENCY` - Limits the number of concurrent HTTP requests in
      flight, (Default: 8)
  """

  def run(args) do
    {_opts, args, _} = OptionParser.parse(args)
    Hex.start

    case args do
      [] -> general()
      _ ->
        Mix.raise "Invalid arguments, expected: mix hex"
    end
  end

  defp general() do
    Hex.Shell.info "Hex v" <> Hex.version
    Hex.Shell.info "Hex is a package manager for the Erlang ecosystem."
    line_break()

    if Hex.Version.match?(System.version, ">= 1.1.0-dev") do
      Hex.Shell.info "Available tasks:"
      line_break()
      Mix.Task.run("help", ["--search", "hex."])
      line_break()
    end

    Hex.Shell.info "Further information can be found here: https://hex.pm/docs/tasks"
  end

  def line_break(), do: Hex.Shell.info ""

  def print_table(header, values) do
    header = Enum.map(header, &[:underline, &1])
    widths = widths([header | values])

    print_row(header, widths)
    Enum.each(values, &print_row(&1, widths))
  end

  defp ansi_length(binary) when is_binary(binary),
    do: byte_size(binary)
  defp ansi_length(list) when is_list(list),
    do: Enum.reduce(list, 0, &(ansi_length(&1) + &2))
  defp ansi_length(atom) when is_atom(atom),
    do: 0

  defp print_row(strings, widths) do
    Enum.zip(strings, widths)
    |> Enum.map(fn {string, width} ->
      pad_size = width - ansi_length(string) + 2
      pad = :lists.duplicate(pad_size, ?\s)
      [string || "", :reset, pad]
    end)
    |> IO.ANSI.format
    |> Hex.Shell.info
  end

  defp widths([head | tail]) do
    widths = Enum.map(head, &ansi_length/1)

    Enum.reduce(tail, widths, fn list, acc ->
      Enum.zip(list, acc)
      |> Enum.map(fn {string, width} -> max(width, ansi_length(string)) end)
    end)
  end

  def generate_key(username, password) do
    Hex.Shell.info("Generating API key...")
    {:ok, name} = :inet.gethostname()
    name = List.to_string(name)

    case Hex.API.Key.new(name, [user: username, pass: password]) do
      {201, body, _} ->
        Hex.Shell.info("Encrypting API key with user password...")
        encrypted_key = Hex.Crypto.encrypt(body["secret"], password, @apikey_tag)
        Hex.Config.update([
          username: username,
          encrypted_key: encrypted_key])

      {code, body, _} ->
        Mix.shell.error("Generation of API key failed (#{code})")
        Hex.Utils.print_error_result(code, body)
    end
  end

  def auth_info(config) do
    cond do
      encrypted_key = config[:encrypted_key] ->
        [key: decrypt_key(encrypted_key)]
      key = config[:key] ->
        Hex.Shell.info "Your stored API key is not encrypted, please " <>
                       "supply a passphrase to encrypt it"
        encrypt_key(config, key)
        [key: key]
      true ->
        Mix.raise "No authorized user found. Run 'mix hex.user auth'"
    end
  end

  def encrypt_key(config, key, challenge \\ "Passphrase") do
    password = password_get("#{challenge}:") |> Hex.string_trim
    confirm = password_get("#{challenge} (confirm):") |> Hex.string_trim
    if password != confirm do
      Mix.raise "Entered passphrases do not match"
    end

    encrypted_key = Hex.Crypto.encrypt(key, password, @apikey_tag)

    config
    |> Keyword.delete(:key)
    |> Keyword.merge([encrypted_key: encrypted_key])
    |> Hex.Config.write
  end

  def decrypt_key(encrypted_key, challenge \\ "Passphrase") do
    password = password_get("#{challenge}:") |> Hex.string_trim
    case Hex.Crypto.decrypt(encrypted_key, password, @apikey_tag) do
      {:ok, key} ->
        key
      :error ->
        Mix.raise "Wrong passphrase"
    end
  end

  def generate_encrypted_key(password, key) do
    encrypted_key = Hex.Crypto.encrypt(key, password, @apikey_tag)
    [encrypted_key: encrypted_key]
  end

  def persist_key(password, key) do
    generate_encrypted_key(password, key)
    |> Hex.Config.update
  end

  def required_opts(opts, required) do
    Enum.map(required, fn req ->
      unless Keyword.has_key?(opts, req) do
        Mix.raise "Missing command line option: #{req}"
      end
    end)
  end

  # Password prompt that hides input by every 1ms
  # clearing the line with stderr
  def password_get(prompt) do
    if Hex.State.fetch!(:clean_pass) do
      password_clean(prompt)
    else
      Hex.Shell.prompt(prompt <> " ")
    end
  end

  defp password_clean(prompt) do
    pid   = spawn_link(fn -> loop(prompt) end)
    ref   = make_ref()
    value = IO.gets(prompt <> " ")

    send pid, {:done, self(), ref}
    receive do: ({:done, ^pid, ^ref}  -> :ok)

    value
  end

  defp loop(prompt) do
    receive do
      {:done, parent, ref} ->
        send parent, {:done, self(), ref}
        IO.write(:standard_error, "\e[2K\r")
    after
      1 ->
        IO.write(:standard_error, "\e[2K\r#{prompt} ")
        loop(prompt)
    end
  end

  @progress_steps 25

  def progress(nil) do
    fn _ -> nil end
  end

  def progress(max) do
    put_progress(0, 0)

    fn size ->
      fraction = size / max
      completed = trunc(fraction * @progress_steps)
      put_progress(completed, trunc(fraction * 100))
      size
    end
  end

  defp put_progress(completed, percent) do
    unfilled = @progress_steps - completed
    str = "\r[#{String.duplicate("#", completed)}#{String.duplicate(" ", unfilled)}]"
    IO.write(:stderr, str <> " #{percent}%")
  end

  def clean_version("v" <> version), do: version
  def clean_version(version),        do: version
end
