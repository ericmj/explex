defmodule Mix.Tasks.Hex.FetchTest do
  use HexTest.Case
  @moduletag :integration

  test "download latest version of a package" do
    in_tmp(fn ->
      Mix.Tasks.Hex.Fetch.run(["ex_doc"])
      parent_directory = File.cwd!()
      message = "Package fetched at: #{parent_directory}/ex_doc-0.1.0.tar"
      assert_received {:mix_shell, :info, [^message]}

      assert File.exists?(Path.join(parent_directory, "ex_doc-0.1.0.tar"))

      error_message = "No package with name no_package"

      assert_raise(Mix.Error, error_message, fn ->
        Mix.Tasks.Hex.Fetch.run(["no_package"])
      end)
    end)
  end

  test "package name is required" do
    message =
      "Invalid arguments, expected:\n\nmix hex.fetch PACKAGE [VERSION] [--output PATH] [--unpack]\n"

    assert_raise(Mix.Error, message, fn ->
      Mix.Tasks.Hex.Fetch.run([])
    end)
  end

  test "download specific version of a package" do
    in_tmp(fn ->
      Mix.Tasks.Hex.Fetch.run(["ex_doc", "0.1.0"])
      parent_directory = File.cwd!()
      message = "Package fetched at: #{parent_directory}/ex_doc-0.1.0.tar"
      assert_received {:mix_shell, :info, [^message]}

      assert File.exists?(Path.join(parent_directory, "ex_doc-0.1.0.tar"))
    end)
  end

  test "unpack package content" do
    in_tmp(fn ->
      Mix.Tasks.Hex.Fetch.run(["ex_doc", "--unpack"])
      parent_directory = File.cwd!()
      message = "Package fetched at: #{parent_directory}/ex_doc-0.1.0.tar"
      assert_received {:mix_shell, :info, [^message]}

      refute File.exists?(Path.join(parent_directory, "ex_doc-0.1.0.tar"))

      assert File.exists?(Path.join(parent_directory, "hex_metadata.config"))
    end)
  end

  test "package in a given directory" do
    in_tmp(fn ->
      parent_directory = Path.join(tmp_path(), "vendor/hex")
      Mix.Tasks.Hex.Fetch.run(["ex_doc", "-o", parent_directory])
      message = "Package fetched at: #{parent_directory}/ex_doc-0.1.0.tar"
      assert_received {:mix_shell, :info, [^message]}

      assert File.exists?(Path.join(parent_directory, "ex_doc-0.1.0.tar"))
    end)
  end
end
