defmodule Protobuf.TypeUtil do
  require Record
  
  Record.defrecord(
    :proto_type,
    code: 0,
    label: :DEFAULT_TYPE,
    type: :default,
    elixir_type: "any()"
  )

  @type t :: record(
    :proto_type,
    code: non_neg_integer(),
    label: atom(),
    type: atom(),
    elixir_type: String.t() | :dynamic
  )
  defp proto_types(), do: [
    proto_type(label: :TYPE_DOUBLE, code: 1, type: :double, elixir_type: "float()"),
    proto_type(label: :TYPE_FLOAT, code: 2, type: :float, elixir_type: "float()"),
    proto_type(label: :TYPE_INT64, code: 3, type: :int64, elixir_type: "integer()"),
    proto_type(label: :TYPE_UINT64, code: 4, type: :uint64, elixir_type: "non_neg_integer()"),
    proto_type(label: :TYPE_INT32, code: 5, type: :int32, elixir_type: "integer()"),
    proto_type(label: :TYPE_FIXED64, code: 6, type: :fixed64, elixir_type: "non_neg_integer()"),
    proto_type(label: :TYPE_FIXED32, code: 7, type: :fixed32, elixir_type: "non_neg_integer()"),
    proto_type(label: :TYPE_BOOL, code: 8, type: :bool, elixir_type: "boolean()"),
    proto_type(label: :TYPE_STRING, code: 9, type: :string, elixir_type: "String.t()"),
    proto_type(label: :TYPE_GROUP, code: 10, type: :group),
    proto_type(label: :TYPE_MESSAGE, code: 11, type: :message, elixir_type: :dynamic),
    proto_type(label: :TYPE_BYTES, code: 12, type: :bytes, elixir_type: "String.t()"),
    proto_type(label: :TYPE_UINT32, code: 13, type: :uint32, elixir_type: "non_neg_integer()"),
    proto_type(label: :TYPE_ENUM, code: 14, type: :enum, elixir_type: "integer()"),
    proto_type(label: :TYPE_SFIXED32, code: 15, type: :sfixed32, elixir_type: "integer()"),
    proto_type(label: :TYPE_SFIXED64, code: 16, type: :sfixed64, elixir_type: "integer()"),
    proto_type(label: :TYPE_SINT32, code: 17, type: :sint32, elixir_type: "integer()"),
    proto_type(label: :TYPE_SINT64, code: 18, type: :sint64, elixir_type: "integer()")
  ]

  @spec find_type(pos_integer() | atom()) :: t()
  defp find_type(data) do
    predicate = case is_atom(data) do
      true -> fn (type) -> proto_type(type, :label) === data end
      false -> fn (type) -> proto_type(type, :code) === data end
    end
    case Enum.find(proto_types(), predicate) do
      nil  -> proto_type()
      type -> type
    end
  end

  def number_to_atom(data), do: data |> find_type() |> proto_type(:type)

  def str_to_spec(data, type) do
    case find_type(data) |> proto_type(:elixir_type) do
      :dynamic  -> "#{type}.t()"
      type -> type
    end
  end
end
