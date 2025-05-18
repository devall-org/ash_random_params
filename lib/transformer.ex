defmodule AshRandomParams.Transformer do
  use Spark.Dsl.Transformer

  alias Ash.Resource.Relationships.BelongsTo
  alias Ash.Resource.Builder

  def transform(dsl_state) do
    dsl_state
    |> add_random_params()
    |> add_random_attr()
  end

  def add_random_params(dsl_state) do
    action = Builder.build_action_argument(:action, :atom, default: :create)
    init_params = Builder.build_action_argument(:init_params, :map, default: %{})
    enforce_random = Builder.build_action_argument(:enforce_random, {:array, :atom}, default: [])
    exclude = Builder.build_action_argument(:exclude, {:array, :atom}, default: [])
    include_defaults? = Builder.build_action_argument(:include_defaults?, :boolean, default: true)

    dsl_state
    |> Builder.add_action(:action, :random_params,
      returns: :map,
      arguments: [action, init_params, exclude, enforce_random, include_defaults?],
      run: &__MODULE__.do_random_params/2
    )
    |> Builder.add_interface(:random_params, args: [:action, {:optional, :init_params}])
  end

  def add_random_attr(dsl_state) do
    attr = Builder.build_action_argument(:attr, :atom)

    dsl_state
    |> Builder.add_action(:action, :random_attr,
      returns: :term,
      arguments: [attr],
      run: &__MODULE__.do_random_attr/2
    )
    |> Builder.add_interface(:random_attr, args: [:attr])
  end

  def do_random_params(
        %Ash.ActionInput{
          resource: resource,
          arguments: %{
            action: action,
            init_params: init_params,
            exclude: exclude,
            enforce_random: enforce_random,
            include_defaults?: include_defaults?
          }
        } =
          input,
        ctx
      ) do
    action = Ash.Resource.Info.action(resource, action)
    init_keys = init_params |> Map.keys()

    belongs_to_attrs =
      resource
      |> Ash.Resource.Info.relationships()
      |> Enum.flat_map(fn
        %BelongsTo{source_attribute: src_attr} -> [src_attr]
        _ -> []
      end)

    rel_names =
      resource
      |> Ash.Resource.Info.relationships()
      |> Enum.map(& &1.name)

    accepted_attrs =
      Ash.Resource.Info.attributes(resource)
      |> Enum.filter(&(&1.name in action.accept))

    candidates = accepted_attrs ++ action.arguments

    defaults =
      if include_defaults? do
        candidates
        |> then(fn attr_or_args ->
          if action.type == :create do
            attr_or_args
          else
            attr_or_args
            |> Enum.reject(&(&1.name in rel_names))
            |> Enum.reject(&(&1.name in belongs_to_attrs))
          end
        end)
        |> Enum.reject(&(&1.name in exclude))
        |> Enum.reject(&(&1.name in init_keys))
        |> Map.new(fn %{name: name, default: default} ->
          value =
            case default do
              default when is_function(default, 0) ->
                default.()

              default ->
                default
            end

          {name, value}
        end)
      else
        %{}
      end

    generated_params =
      (
        {random_mod, random_opts} =
          random = AshRandomParams.Info.random_params_random!(input.resource)

        fields_by_exclude =
          candidates
          |> Enum.reject(&(&1.name in rel_names))
          |> Enum.reject(&(&1.name in belongs_to_attrs))
          |> Enum.reject(&(&1.name in exclude))
          |> Enum.reject(&(&1.allow_nil? || &1.default != nil))

        fields_by_fill = candidates |> Enum.filter(&(&1.name in enforce_random))

        (fields_by_exclude ++ fields_by_fill)
        |> Enum.reject(&(&1.name in init_keys))
        |> Map.new(fn %{name: name, default: default} = attr_or_arg ->
          value =
            case default do
              nil ->
                random_mod.random(attr_or_arg, random_opts, %{random: random, action_context: ctx})

              default when is_function(default, 0) ->
                default.()

              default ->
                default
            end

          {name, value}
        end)
      )

    result_params = defaults |> Map.merge(init_params) |> Map.merge(generated_params)

    {:ok, result_params}
  end

  def do_random_attr(%Ash.ActionInput{resource: resource, arguments: %{attr: attr}}, ctx) do
    {random_mod, random_opts} = random = AshRandomParams.Info.random_params_random!(resource)
    attr = Ash.Resource.Info.attribute(resource, attr)

    {:ok, random_mod.random(attr, random_opts, %{random: random, action_context: ctx})}
  end
end
