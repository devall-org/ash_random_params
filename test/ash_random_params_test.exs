defmodule AshRandomParamsTest do
  use ExUnit.Case, async: true

  alias __MODULE__.{Random, Post, Author, Domain}

  defmodule Post do
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Ets, extensions: [AshRandomParams]

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id

      attribute :req_str, :string, allow_nil?: false, public?: true
      attribute :opt_str, :string, allow_nil?: true, public?: true

      attribute :req_int, :integer, allow_nil?: false, public?: true
      attribute :opt_int, :integer, allow_nil?: false, public?: true, default: 123
    end

    actions do
      defaults [:read, :destroy]

      create :create do
        accept :*
        argument :author, :struct, allow_nil?: false, constraints: [instance_of: Author]
      end

      update :update do
        accept :*
        argument :author, :struct, allow_nil?: false, constraints: [instance_of: Author]
      end
    end

    relationships do
      belongs_to :author, Author, allow_nil?: false, public?: true
    end

    random_params do
      random Random
    end
  end

  defmodule Author do
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Ets

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id
    end

    relationships do
      has_many :posts, Post, public?: true
    end

    actions do
      defaults [:read, :destroy, create: :*, update: :*]
    end
  end

  defmodule Random do
    use AshRandomParams.Random

    @impl AshRandomParams.Random
    def random(%{type: Ash.Type.Integer}, _opts, _context) do
      777
    end

    @impl AshRandomParams.Random
    def random(attr_or_arg, opts, context) do
      AshRandomParams.DefaultRandom.random(attr_or_arg, opts, context)
    end
  end

  defmodule Domain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource Post
      resource Author
    end
  end

  test "create action" do
    assert %{
             author: nil,
             author_id: nil,
             req_str: "req_str-" <> _,
             opt_str: nil,
             req_int: 777,
             opt_int: 123
           } =
             Post
             |> Ash.ActionInput.for_action(
               :random_params,
               %{
                 action: :create
               }
             )
             |> Ash.run_action!()
  end

  test "update action" do
    assert %{
             req_str: "req_str-" <> _,
             opt_str: nil,
             req_int: 777,
             opt_int: 123
           } =
             params =
             Post
             |> Ash.ActionInput.for_action(
               :random_params,
               %{
                 action: :update
               }
             )
             |> Ash.run_action!()

    refute Map.has_key?(params, :author)
    refute Map.has_key?(params, :author_id)
  end

  describe "options" do
    test "with init_params" do
      assert %{
               author_id: nil,
               req_str: "req_str-" <> _,
               opt_str: nil,
               req_int: 123_456,
               opt_int: 123
             } =
               Post
               |> Ash.ActionInput.for_action(
                 :random_params,
                 %{
                   action: :create,
                   init_params: %{
                     req_int: 123_456
                   }
                 }
               )
               |> Ash.run_action!()
    end

    test "with enforce_random" do
      assert %{
               author_id: nil,
               req_str: "req_str-" <> _,
               opt_str: "opt_str-" <> _,
               req_int: 777,
               opt_int: 123
             } =
               Post
               |> Ash.ActionInput.for_action(
                 :random_params,
                 %{
                   action: :create,
                   enforce_random: [:opt_str]
                 }
               )
               |> Ash.run_action!()
    end

    test "with exclude" do
      assert %{
               author_id: nil,
               opt_str: nil,
               req_int: 777,
               opt_int: 123
             } =
               params =
               Post
               |> Ash.ActionInput.for_action(
                 :random_params,
                 %{
                   action: :create,
                   exclude: [:req_str]
                 }
               )
               |> Ash.run_action!()

      refute params |> Map.has_key?(:req_str)
    end

    test "with include_defaults? false" do
      assert %{
               req_str: "req_str-" <> _,
               req_int: 777
             } =
               params =
               Post
               |> Ash.ActionInput.for_action(
                 :random_params,
                 %{
                   action: :create,
                   include_defaults?: false
                 }
               )
               |> Ash.run_action!()

      refute params |> Map.has_key?(:opt_str)
      refute params |> Map.has_key?(:opt_int)
      refute params |> Map.has_key?(:author_id)
    end
  end

  test "code interface" do
    assert %{
             author_id: nil,
             req_str: "req_str-" <> _,
             opt_str: nil,
             req_int: 777,
             opt_int: 123
           } =
             Post.random_params!(:create)

    assert %{
             author_id: nil,
             req_str: "req_str-" <> _,
             opt_str: nil,
             req_int: 123,
             opt_int: 456
           } =
             Post.random_params!(:create, %{req_int: 123, opt_int: 456})

    assert %{
             author_id: nil,
             req_str: "req_str-" <> _,
             opt_str: nil,
             req_int: 777,
             opt_int: 456
           } =
             Post.random_params!(
               :create,
               %{opt_int: 456},
               %{enforce_random: [:opt_int]}
             )
  end
end
