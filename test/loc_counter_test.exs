defmodule LocCounterTest do
  use ExUnit.Case
  doctest LocCounter

  test "greets the world" do
    assert LocCounter.hello() == :world
  end
end
