defmodule Mix.Tasks.HexTest do
  use HexTest.Case

  test "run without args shows help" do
    System.put_env("MIX_NO_DEPS", "1")

    try do
      Mix.Tasks.Hex.run([])
      assert_received {:mix_shell, :info, ["Hex is a package manager for the Erlang ecosystem."]}
    after
      System.put_env("MIX_NO_DEPS", "0")
    end
  end
end
