defmodule ProtobufTest do
  use ExUnit.Case
  doctest Protobuf

  test "greets the world" do
    assert Protobuf.hello() == :world
  end
end
