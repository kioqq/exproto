defmodule Protobuf do
  alias Protobuf.{Encoder, Decoder, Builder}

  defmacro __using__(opts) do
    quote do
      import Protobuf.DSL, only: [field: 3, field: 2, oneof: 2]
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :oneofs, accumulate: true)

      @options unquote(opts)
      unquote(encode_decode())
      @before_compile Protobuf.DSL

      def new, do: new(%{})

      def new(attrs) when is_list(attrs) do
        attrs |> Enum.into(%{}) |> new()
      end

      def new(attrs) do
        Builder.new(__MODULE__, attrs)
      end

      def from_params(params \\ %{}) do
        Protobuf.Builder.from_params(__MODULE__, params)
      end
    end
  end

  defp encode_decode do
    quote do
      def decode(data), do: Decoder.decode(data, __MODULE__)
      def encode(struct), do: Encoder.encode(struct)
    end
  end

  def decode(%{__struct__: mod} = data) do
    Decoder.decode(data, mod)
  end

  def encode(struct) do
    Encoder.encode(struct)
  end
end
