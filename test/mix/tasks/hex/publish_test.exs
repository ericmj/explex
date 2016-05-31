defmodule Mix.Tasks.Hex.PublishTest do
  use HexTest.Case
  @moduletag :integration

  test "validate" do
    Mix.Project.push ReleaseSimple.Mixfile
    Hex.State.put(:home, tmp_path("does_not_exist"))

    assert_raise Mix.Error, "No authorized user found. Run 'mix hex.user auth'", fn ->
      Mix.Tasks.Hex.Publish.run([])
    end
  after
    purge [ReleaseSimple.Mixfile]
  end

  test "create and revert" do
    Mix.Project.push ReleaseSimple.Mixfile

    in_tmp fn ->
      Hex.State.put(:home, tmp_path())
      setup_auth("user", "hunter42")

      send self, {:mix_shell_input, :yes?, true}
      Mix.Tasks.Hex.Publish.run(["--no-progress"])
      assert {200, _, _} = Hex.API.Release.get("release_a", "0.0.1")

      msg = "Before publishing, please read Hex Code of Conduct: https://hex.pm/policies/codeofconduct"
      assert_received {:mix_shell, :info, [^msg]}

      send self, {:mix_shell_input, :yes?, true}
      Mix.Tasks.Hex.Publish.run(["--revert", "0.0.1"])
      assert {404, _, _} = Hex.API.Release.get("release_a", "0.0.1")
    end
  after
    purge [ReleaseSimple.Mixfile]
  end

  test "create with package name" do
    Mix.Project.push ReleaseName.Mixfile

    in_tmp fn ->
      Hex.State.put(:home, tmp_path())
      setup_auth("user", "hunter42")

      send self, {:mix_shell_input, :yes?, true}
      Mix.Tasks.Hex.Publish.run(["--no-progress"])
      assert {200, body, _} = Hex.API.Release.get("released_name", "0.0.1")
      assert body["meta"]["app"] == "release_d"
    end
  after
    purge [ReleaseName.Mixfile]
  end

  test "create with key" do
    Mix.Project.push ReleaseSimple.Mixfile

    in_tmp fn ->
      Hex.State.put(:home, tmp_path())
      setup_auth("user", "hunter42")

      send self, {:mix_shell_input, :yes?, true}
      Mix.Tasks.Hex.Publish.run(["--no-progress"])
      assert {200, _, _} = Hex.API.Release.get("release_a", "0.0.1")
    end
  after
    purge [ReleaseSimple.Mixfile]
  end

  test "create with deps" do
    Mix.Project.push ReleaseDeps.Mixfile

    in_tmp fn ->
      Hex.State.put(:home, tmp_path())
      setup_auth("user", "hunter42")

      Mix.Tasks.Deps.Get.run([])

      send self, {:mix_shell_input, :yes?, true}
      Mix.Tasks.Hex.Publish.run(["--no-progress"])

      assert_received {:mix_shell, :info, ["\e[33m  WARNING! No files\e[0m"]}
      assert_received {:mix_shell, :info, ["\e[33m  WARNING! Missing metadata fields: maintainers, links\e[0m"]}
      assert {200, _, _} = Hex.API.Release.get("release_b", "0.0.2")
    end
  after
    purge [ReleaseDeps.Mixfile]
  end

  test "create with meta" do
    Mix.Project.push ReleaseMeta.Mixfile

    in_tmp fn ->
      Hex.State.put(:home, tmp_path())
      setup_auth("user", "hunter42")

      File.write!("myfile.txt", "hello")
      send self, {:mix_shell_input, :yes?, true}
      Mix.Tasks.Hex.Publish.run(["--no-progress"])

      assert_received {:mix_shell, :info, ["Publishing release_c 0.0.3"]}
      assert_received {:mix_shell, :info, ["  Files:"]}
      assert_received {:mix_shell, :info, ["    myfile.txt"]}
      assert_received {:mix_shell, :info, ["\e[33m  WARNING! Missing files: missing.txt, missing/*" <> _]}
      assert_received {:mix_shell, :info, ["  Extra: \n    c: d"]}
      refute_received {:mix_shell, :info, ["\e[33m  WARNING! Missing metadata fields" <> _]}
    end
  after
    purge [ReleaseMeta.Mixfile]
  end
end
