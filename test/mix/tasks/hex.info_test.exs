defmodule Mix.Tasks.Hex.InfoTest do
  use HexTest.Case
  @moduletag :integration

  test "package" do
    Mix.Tasks.Hex.Info.run(["ex_doc"])
    assert_received {:mix_shell, :info, ["Some description\n"]}
    assert_received {:mix_shell, :info, ["Config: {:ex_doc, \"~> 0.1.0\"}"]}
    assert_received {:mix_shell, :info, ["Maintainers: John Doe, Jane Doe"]}
    assert_received {:mix_shell, :info, ["Releases: 0.1.0, 0.1.0-rc1, 0.0.1\n"]}

    Mix.Tasks.Hex.Info.run(["no_package"])
    assert_received {:mix_shell, :error, ["No package with name no_package"]}
  end

  test "package with retired release" do
    Mix.Tasks.Hex.Info.run(["tired"])
    assert_received {:mix_shell, :info, ["Releases: 0.2.0, 0.1.0 (retired)\n"]}
  end

  test "package with --organization flag" do
    in_tmp(fn ->
      Hex.State.put(:home, tmp_path())
      auth = Hexpm.new_user("infoorg", "infoorg@mail.com", "password", "infoorg")
      Hexpm.new_repo("infoorg", auth)
      Mix.Tasks.Hex.update_key(auth[:"$encrypted_key"])

      bypass_repo("infoorg")
      send(self(), {:mix_shell_input, :prompt, "password"})
      Mix.Tasks.Hex.Info.run(["ecto", "--organization", "infoorg"])
      assert_received {:mix_shell, :info, ["ecto description\n"]}
    end)
  end

  test "release" do
    Mix.Tasks.Hex.Info.run(["ex_doc", "0.0.1"])
    assert_received {:mix_shell, :info, ["Config: {:ex_doc, \"~> 0.0.1\"}"]}

    Mix.Tasks.Hex.Info.run(["ex_doc", "0.1.0-rc1"])
    assert_received {:mix_shell, :info, ["Config: {:ex_doc, \"~> 0.1.0-rc1\"}"]}

    Mix.Tasks.Hex.Info.run(["ex_doc", "1.2.3"])
    assert_received {:mix_shell, :error, ["No release with name ex_doc 1.2.3"]}
  end

  test "latest_release/2" do
    import Mix.Tasks.Hex.Info, only: [latest_release: 2]

    v1_1_0_rc1 = %{"version" => "1.1.0-rc.1"}
    v1_1_0_rc0 = %{"version" => "1.1.0-rc.0"}
    v1_0_1 = %{"version" => "1.0.1"}
    v1_0_0 = %{"version" => "1.0.0"}

    assert latest_release([v1_0_1, v1_0_0], []) == v1_0_1

    assert latest_release([v1_1_0_rc1, v1_0_0], []) == v1_0_0
    assert latest_release([v1_1_0_rc1, v1_1_0_rc0], []) == v1_1_0_rc1

    assert latest_release([v1_0_1, v1_0_0], ["1.0.1"]) == v1_0_0
    assert latest_release([v1_0_1, v1_0_0], ["1.0.1", "1.0.0"]) == v1_0_1
  end
end
