defmodule FlowmailerAdapterTest do
  use ExUnit.Case
  doctest FlowmailerAdapter

  test "greets the world" do
    assert FlowmailerAdapter.hello() == :world
  end
end
