defmodule Mix.Tasks.Hex.PackageTest do
  use HexTest.Case
  @moduletag :integration

  test "fetch: success" do
    in_tmp(fn ->
      cwd = File.cwd!()
      Mix.Tasks.Hex.Package.run(["fetch", "ex_doc", "0.0.1"])
      msg = "ex_doc v0.0.1 downloaded to #{cwd}/ex_doc-0.0.1.tar"
      assert_received {:mix_shell, :info, [^msg]}
      assert File.exists?("#{cwd}/ex_doc-0.0.1.tar")
    end)
  end

  test "fetch: package not found" do
    assert_raise Mix.Error, ~r"Request failed \(404\)", fn ->
      Mix.Tasks.Hex.Package.run(["fetch", "ex_doc", "2.0.0"])
    end
  end

  test "diff: success" do
    in_tmp(fn ->
      Hex.State.put(:diff_command, "git diff --no-index --no-color __PATH1__ __PATH2__")

      assert catch_throw(Mix.Tasks.Hex.Package.run(["diff", "ex_doc", "0.0.1..0.1.0"])) ==
               {:exit_code, 1}

      assert_received {:mix_shell, :run, [out]}
      assert out =~ ~s(-{<<"version">>,<<"0.0.1">>}.)
      assert out =~ ~s(+{<<"version">>,<<"0.1.0">>}.)
    end)
  end

  test "diff: custom diff command" do
    in_tmp(fn ->
      Hex.State.put(:diff_command, "ls __PATH1__ __PATH2__")

      assert catch_throw(Mix.Tasks.Hex.Package.run(["diff", "ex_doc", "0.0.1..0.1.0"])) ==
               {:exit_code, 0}

      assert_received {:mix_shell, :run, [out]}
      assert out =~ "hex_metadata.config\nmix.exs"
    end)
  end

  test "diff: bad version range" do
    msg = "Expected version range to be in format `VERSION1..VERSION2`, got: `\"1.0.0..\"`"

    assert_raise Mix.Error, msg, fn ->
      Mix.Tasks.Hex.Package.run(["diff", "ex_doc", "1.0.0.."])
    end
  end

  test "diff: package not found" do
    Hex.State.put(:shell_process, self())

    assert_raise Mix.Error, ~r"Request failed \(404\)", fn ->
      Mix.Tasks.Hex.Package.run(["diff", "bad", "1.0.0..1.1.0"])
    end

    in_tmp(fn ->
      assert_raise Mix.Error, ~r"Request failed \(404\)", fn ->
        Mix.Tasks.Hex.Package.run(["diff", "ex_doc", "0.0.1..2.0.0"])
      end
    end)
  end
end
