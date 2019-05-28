defmodule Protobuf.Protoc.Generator.Message do
  alias Protobuf.Protoc.Generator.Util
  alias Protobuf.TypeUtil
  alias Protobuf.Protoc.Generator.Enum, as: EnumGenerator

  def generate_list(ctx, descs) do
    Enum.map(descs, fn desc -> generate(ctx, desc) end)
  end

  def generate(ctx, desc) do
    msg_struct = parse_desc(ctx, desc)
    ctx = %{ctx | namespace: msg_struct[:new_namespace]}
    [gen_msg(ctx.syntax, msg_struct)] ++ gen_nested_msgs(ctx, desc) ++ gen_nested_enums(ctx, desc)
  end

  def parse_desc(%{custom_namespace: cns, namespace: ns, package: pkg} = ctx, desc) do
    new_ns = ns ++ [Util.trans_name(desc.name)]
    fields = get_fields(ctx, desc)

    %{
      new_namespace: new_ns,
      name: new_ns |> Util.join_name() |> Util.attach_pkg(pkg) |> Util.attach_ns(cns),
      options: msg_opts_str(ctx, desc.options),
      structs: structs_str(desc),
      typespec: typespec_str(fields, desc.oneof_decl),
      fields: fields,
      oneofs: oneofs_str(desc.oneof_decl)
    }
  end

  defp gen_msg(syntax, msg_struct) do
    Protobuf.Protoc.Template.message(
      msg_struct[:name],
      msg_struct[:options],
      msg_struct[:structs],
      msg_struct[:typespec],
      msg_struct[:oneofs],
      gen_fields(syntax, msg_struct[:fields])
    )
  end

  defp gen_nested_msgs(ctx, desc) do
    Enum.map(desc.nested_type, fn msg_desc -> generate(ctx, msg_desc) end)
  end

  defp gen_nested_enums(ctx, desc) do
    Enum.map(desc.enum_type, fn enum_desc -> EnumGenerator.generate(ctx, enum_desc) end)
  end

  defp gen_fields(syntax, fields) do
    Enum.map(fields, fn %{opts: opts} = f ->
      opts_str = Util.options_to_str(opts)
      opts_str = if opts_str == "", do: "", else: ", " <> opts_str

      label_str =
        if syntax == :proto3 && f[:label] != "repeated", do: "", else: "#{f[:label]}: true, "

      ":#{f[:name]}, #{f[:number]}, #{label_str}type: #{f[:type]}#{opts_str}"
    end)
  end

  def msg_opts_str(%{syntax: syntax}, opts) do
    msg_options = opts

    opts = %{
      syntax: syntax,
      map: msg_options && msg_options.map_entry,
      deprecated: msg_options && msg_options.deprecated
    }

    str = Util.options_to_str(opts)
    if String.length(str) > 0, do: ", " <> str, else: ""
  end

  def structs_str(struct) do
    fields = Enum.filter(struct.field, fn f -> !f.oneof_index end)
    Enum.map_join(struct.oneof_decl ++ fields, ", ", fn f -> ":#{f.name}" end)
  end

  def typespec_str([], []) do
    "  @type t :: %__MODULE__{}\n"
  end

  def typespec_str(fields, oneofs) do
    longest_field = fields |> Enum.max_by(&String.length(&1[:name]))
    longest_width = String.length(longest_field[:name])
    fields = Enum.filter(fields, fn f -> !f[:oneof] end)

    types =
      Enum.map(oneofs, fn f ->
        {fmt_type_name(f.name, longest_width), "{atom, any}"}
      end) ++
        Enum.map(fields, fn f ->
          {fmt_type_name(f[:name], longest_width), fmt_type(f)}
        end)

    "  @type t :: %__MODULE__{\n" <>
      Enum.map_join(types, ",\n", fn {k, v} ->
        "    #{k} #{v}"
      end) <> "\n  }\n"
  end

  defp oneofs_str(oneofs) do
    oneofs
    |> Enum.with_index()
    |> Enum.map(fn {oneof, index} ->
      "oneof :#{oneof.name}, #{index}"
    end)
  end

  defp fmt_type_name(name, len) do
    String.pad_trailing("#{name}:", len + 1)
  end

  defp fmt_type(%{opts: %{enum: true}, label: "repeated"}), do: "[integer]"
  defp fmt_type(%{opts: %{enum: true}}), do: "integer"

  defp fmt_type(%{opts: %{map: true}, map: {{k_type, k_name}, {v_type, v_name}}}) do
    k_type = type_to_spec(k_type, k_name)
    v_type = type_to_spec(v_type, v_name)
    "%{#{k_type} => #{v_type}}"
  end

  defp fmt_type(%{label: "repeated", type_num: type_num, type: type}) do
    "[#{type_to_spec(type_num, type)}]"
  end

  defp fmt_type(%{type_num: type_num, type: type}) do
    "#{type_to_spec(type_num, type)}"
  end

  defp type_to_spec(11, type), do: TypeUtil.str_to_spec(11, type)
  defp type_to_spec(:TYPE_MESSAGE, type), do: TypeUtil.str_to_spec(:TYPE_MESSAGE, type)
  defp type_to_spec(num, _), do: TypeUtil.str_to_spec(num)

  def get_fields(ctx, desc) do
    oneofs = Enum.map(desc.oneof_decl, & &1.name)
    nested_maps = nested_maps(ctx, desc)
    Enum.map(desc.field, fn f -> get_field(ctx, f, nested_maps, oneofs) end)
  end

  def get_field(ctx, f, nested_maps, oneofs) do
    opts = field_options(f)
    map = nested_maps[f.type_name]
    opts = if map, do: Map.put(opts, :map, true), else: opts

    opts =
      if length(oneofs) > 0 && f.oneof_index, do: Map.put(opts, :oneof, f.oneof_index), else: opts

    type = TypeUtil.number_to_atom(f.type)

    type =
      if type == :enum || type == :message do
        Util.trans_type_name(f.type_name, ctx)
      else
        ":#{type}"
      end

    %{
      name: f.name,
      number: f.number,
      label: label_name(f.label),
      type: type,
      type_num: f.type,
      opts: opts,
      map: map,
      oneof: f.oneof_index
    }
  end

  # Map of protobuf are actually nested(one level) messages
  defp nested_maps(ctx, desc) do
    full_name = Util.join_name([ctx.package | ctx.namespace] ++ [desc.name])
    prefix = "." <> full_name

    Enum.reduce(desc.nested_type, %{}, fn desc, acc ->
      cond do
        desc.options && desc.options.map_entry ->
          [k, v] = Enum.sort(desc.field, &(&1.number < &2.number))

          pair =
            {{k.type, Util.trans_type_name(k.type_name || "", ctx)},
             {v.type, Util.trans_type_name(v.type_name || "", ctx)}}

          Map.put(acc, Util.join_name([prefix, desc.name]), pair)

        true ->
          acc
      end
    end)
  end

  defp field_options(f) do
    opts = %{enum: f.type == 14, default: default_value(f.type, f.default_value)}
    if f.options, do: merge_field_options(opts, f), else: opts
  end

  defp label_name(1), do: "optional"
  defp label_name(2), do: "required"
  defp label_name(3), do: "repeated"

  defp label_name(:LABEL_OPTIONAL), do: "optional"
  defp label_name(:LABEL_REQUIRED), do: "required"
  defp label_name(:LABEL_REPEATED), do: "repeated"

  defp default_value(_, ""), do: nil
  defp default_value(_, nil), do: nil

  defp default_value(type, value) do
    # IO.inspect(type)

    val =
      cond do
        type in [2, :TYPE_FLOAT] ->
          case Float.parse(value) do
            {v, _} -> v
            :error -> value
          end

        type in [
          7, 13, 15, 16, 17, 18,
          :TYPE_FIXED64, :TYPE_UINT32,
          :TYPE_SFIXED32, :TYPE_SFIXED64,
          :TYPE_SINT32, :TYPE_SINT64
        ] ->
          case Integer.parse(value) do
            {v, _} -> v
            :error -> value
          end

        type in [9, 12, 14, 8, :TYPE_STRING, :TYPE_ENUM, :TYPE_STRING, :TYPE_BYTES] ->
          value

        true ->
          nil
      end

    if val == nil, do: val, else: inspect(val)
  end

  defp merge_field_options(opts, f) do
    opts
    |> Map.put(:packed, f.options.packed)
    |> Map.put(:deprecated, f.options.deprecated)
  end
end
