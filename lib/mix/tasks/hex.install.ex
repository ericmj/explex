defmodule Mix.Tasks.Hex.Install do
  use Mix.Task
  @hex_mirror "https://repo.hex.pm"
  @hex_list_path "/installs/hex-1.x.csv"
  @hex_archive_path "/installs/[ELIXIR_VERSION]/hex-[HEX_VERSION].ez"
  @public_keys_html "https://repo.hex.pm/installs/public_keys.html"

  @shortdoc false

  @moduledoc false
  @behaviour Hex.Mix.TaskDescription

  @impl true
  def run(args) do
    case args do
      [version] ->
        install(version)

      _ ->
        Mix.raise("""
        Invalid arguments, expected:

        mix hex.install VERSION
        """)
    end
  end

  @impl true
  def tasks() do
    [
      {"VERSION", "Manually install specific Hex version"}
    ]
  end

  defp install(hex_version) do
    raise_if_invalid_version(hex_version)

    hex_url = mirror()
    csv_url = hex_url <> @hex_list_path

    case find_matching_versions_from_signed_csv!("Hex", csv_url, hex_version) do
      {elixir_version, sha512} ->
        archive_url =
          (hex_url <> @hex_archive_path)
          |> String.replace("[ELIXIR_VERSION]", elixir_version)
          |> String.replace("[HEX_VERSION]", hex_version)

        Mix.Tasks.Archive.Install.run([archive_url, "--sha512", sha512, "--force"])

      nil ->
        Mix.raise(
          "Failed to find installation for Hex #{hex_version} and Elixir #{System.version()}"
        )
    end
  end

  defp find_matching_versions_from_signed_csv!(name, path, hex_version) do
    # this is safe because the fetched contents are checked using Mix.PublicKey.verify
    opts = [unsafe_uri: true]

    csv = read_path!(name, path, opts)

    signature =
      read_path!(name, path <> ".signed", opts)
      |> String.replace("\n", "")
      |> Base.decode64!()

    if Mix.PublicKey.verify(csv, :sha512, signature) do
      csv
      |> parse_csv()
      |> find_eligible_version(hex_version)
    else
      Mix.raise(
        "Could not install #{name} because Hex could not verify authenticity " <>
          "of metadata file at #{path}. This may happen because a proxy or some " <>
          "entity is interfering with the download or because you don't have a " <>
          "public key to verify the download.\n\nYou may try again later or check " <>
          "if a new public key has been released in our public keys page: #{@public_keys_html}"
      )
    end
  end

  defp read_path!(name, path, opts) do
    case Mix.Utils.read_path(path, opts) do
      {:ok, contents} ->
        contents

      {:remote, message} ->
        Mix.raise("""
        #{message}

        Could not install #{name} because Hex could not download metadata at #{path}.
        """)
    end
  end

  defp parse_csv(body) do
    body
    |> :binary.split("\n", [:global, :trim])
    |> Enum.map(&:binary.split(&1, ",", [:global, :trim]))
  end

  defp find_eligible_version(entries, hex_version) do
    elixir_version = Version.parse!(System.version())

    entries
    |> Enum.reverse()
    |> Enum.find_value(&find_version(&1, elixir_version, hex_version))
  end

  defp find_version([hex_version, digest | versions], elixir_version, hex_version) do
    if version = Enum.find(versions, &(Version.compare(&1, elixir_version) != :gt)) do
      {version, digest}
    end
  end

  defp find_version(_versions, _elixir_version, _hex_version) do
    nil
  end

  defp raise_if_invalid_version(hex_version) do
    case Version.parse(hex_version) do
      {:ok, _version} -> :ok
      :error -> Mix.raise("#{hex_version} is not a valid Hex version")
    end
  end

  defp mirror() do
    System.get_env("HEX_MIRROR") || @hex_mirror
  end
end
