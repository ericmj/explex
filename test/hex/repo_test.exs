defmodule Hex.RepoTest do
  use HexTest.Case
  @moduletag :integration

  @private_key File.read!(Path.join(__DIR__, "../fixtures/test_priv.pem"))

  test "get_package" do
    assert {:ok, {200, _, _}} = Hex.Repo.get_package("hexpm", "postgrex", "")

    assert_raise Mix.Error, ~r"Unknown repository \"bad\"", fn ->
      Hex.Repo.get_package("bad", "postgrex", "")
    end
  end

  test "verify signature" do
    message = :mix_hex_registry.sign_protobuf("payload", @private_key)
    assert Hex.Repo.verify(message, "hexpm") == "payload"

    assert_raise(Mix.Error, fn ->
      message = :mix_hex_pb_signed.encode_msg(%{payload: "payload", signature: "foobar"}, :Signed)
      Hex.Repo.verify(message, "hexpm")
    end)
  end

  test "decode package" do
    package = %{releases: [], repository: "hexpm", name: "ecto"}
    message = :mix_hex_pb_package.encode_msg(package, :Package)

    assert Hex.Repo.decode_package(message, "hexpm", "ecto") == []
  end

  test "decode package verify origin" do
    package = %{releases: [], repository: "hexpm", name: "ecto"}
    message = :mix_hex_pb_package.encode_msg(package, :Package)

    assert_raise(Mix.Error, fn ->
      Hex.Repo.decode_package(message, "other repo", "ecto")
    end)

    assert_raise(Mix.Error, fn ->
      Hex.Repo.decode_package(message, "hexpm", "other package")
    end)

    Hex.State.put(:no_verify_repo_origin, true)
    assert Hex.Repo.decode_package(message, "other repo", "ecto") == []
    assert Hex.Repo.decode_package(message, "hexpm", "other package") == []
  end

  test "get public key" do
    bypass = Bypass.open()
    repos = Hex.State.fetch!(:repos)
    hexpm = Hex.Repo.default_hexpm_repo()
    repos = put_in(repos["hexpm"].url, "http://localhost:#{bypass.port}")
    Hex.State.put(:repos, repos)

    Bypass.expect(bypass, fn %Plug.Conn{request_path: path} = conn ->
      case path do
        "/public_key" ->
          Plug.Conn.resp(conn, 200, hexpm.public_key)

        "/not_found/public_key" ->
          Plug.Conn.resp(conn, 404, "not found")
      end
    end)

    assert {:ok, {200, public_key, _}} =
             Hex.Repo.get_public_key("http://localhost:#{bypass.port}", nil)

    assert public_key == hexpm.public_key

    assert {:ok, {404, "not found", _}} =
             Hex.Repo.get_public_key("http://localhost:#{bypass.port}/not_found", nil)
  end
end
