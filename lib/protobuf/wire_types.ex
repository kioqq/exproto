defmodule Protobuf.WireTypes do
  @moduledoc """
  Protocol buffer wire types.
  """

  defmacro wire_varint, do: 0
  defmacro wire_64bits, do: 1
  defmacro wire_delimited, do: 2
  defmacro wire_32bits, do: 5
end
