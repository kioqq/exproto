defmodule TestPb.EmptyStruct do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{}
  defstruct []

end

defmodule TestPb.User do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
    id:       integer(),
    id1:      integer(),
    id2:      [integer()],
    id4:      integer(),
    id5:      float(),
    id6:      float(),
    id7:      non_neg_integer(),
    id8:      non_neg_integer(),
    id9:      non_neg_integer(),
    id10:     boolean(),
    id11:     String.t(),
    id13:     String.t(),
    id14:     non_neg_integer(),
    id15:     integer(),
    id16:     integer(),
    test_msg: TestPb.User.Test.t()
  }
  defstruct [:id, :id1, :id2, :id4, :id5, :id6, :id7, :id8, :id9, :id10, :id11, :id13, :id14, :id15, :id16, :test_msg]

  field :id, 1, optional: true, type: :int32
  field :id1, 2, required: true, type: :int32
  field :id2, 3, repeated: true, type: :int32
  field :id4, 4, required: true, type: :int64
  field :id5, 5, required: true, type: :double
  field :id6, 6, required: true, type: :float
  field :id7, 7, required: true, type: :uint64
  field :id8, 8, required: true, type: :fixed64
  field :id9, 9, required: true, type: :fixed64
  field :id10, 10, required: true, type: :bool
  field :id11, 11, required: true, type: :string
  field :id13, 13, required: true, type: :bytes
  field :id14, 14, required: true, type: :uint32
  field :id15, 15, required: true, type: :sint32
  field :id16, 16, required: true, type: :sint64
  field :test_msg, 17, required: true, type: TestPb.User.Test
end

defmodule TestPb.User.Test do
  @moduledoc false
  use Protobuf, syntax: :proto2

  @type t :: %__MODULE__{
    enum:   integer,
    path:   String.t(),
    method: String.t()
  }
  defstruct [:enum, :path, :method]

  field :enum, 1, optional: true, type: TestPb.User.TestEnum, enum: true
  field :path, 2, optional: true, type: :string, default: "/reset_passcode/reset"
  field :method, 3, optional: true, type: :string, default: "post"
end

defmodule TestPb.User.TestEnum do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto2

  field :VALUE1, 1
  field :VALUE2, 2
end
