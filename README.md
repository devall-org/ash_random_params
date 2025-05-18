# AshRandomParams

A library that generates random parameters for Ash resource actions. It provides a convenient way to create random test data for your Ash resources by automatically generating random values for accepts and arguments.

## Usage

Add the `random_params` DSL to your Ash resource:

```elixir
defmodule Post do
  use Ash.Resource, extensions: [AshRandomParams]

  attributes do
    uuid_primary_key :id
    attribute :author, :string, allow_nil?: false
    attribute :title, :string, allow_nil?: false
    attribute :content, :string, allow_nil?: true
    attribute :tag, :string, allow_nil?: false, default: "JS"
  end

  random_params do
    random MyRandom  # Optional: specify your custom random generator
  end
end
```

### Using Random Params

```elixir
# Basic usage
Post.random_params!(:create)
=> %{author: "author-81491", title: "title-388112", content: nil, tag: "JS"}

# With initial params
Post.random_params!(:create, %{author: "James"})
=> %{author: "James", title: "title-388112", content: nil, tag: "JS"}

# With options
Post.random_params!(:create, %{author: "James"}, %{
  enforce_random: [:content],   
  exclude: [:title],   
  include_defaults?: false
})
=> %{author: "James", content: "content-38128"}
```

### Default Behavior

By default, it generates random values for accepts and arguments that have `allow_nil?: false` and no default value (`default == nil`). In the example above, `author` and `title` fall into this category.

### Belongs To Relationships

For accepts and arguments that match the `name` or `source_attribute` of a `belongs_to` relationship:
- In `create` actions, they are generated with `nil` values
- In other actions, they are not generated at all

This behavior exists because:
- In `create` actions, excluding a value is equivalent to setting it to `nil`
- In `update` actions, excluding a value preserves the existing relationship, while explicitly setting it to `nil` removes the relationship

### Options

- `enforce_random`: Forces generation of random values for specified accepts/arguments, overriding the default behavior
- `exclude`: Prevents generation of random values for specified accepts/arguments, overriding the default behavior
- `include_defaults?`: When set to `true`, includes default values for accepts/arguments that have either `allow_nil?: true` or a non-nil default value. Defaults to `true`. In the example above, this would add `%{content: nil, tag: "JS"}` to the generated params.

### Custom Random Generator

You can implement a custom random generator by using the `AshRandomParams.Random` behaviour:

```elixir
defmodule MyRandom do
  use AshRandomParams.Random

  @impl AshRandomParams.Random
  def random(%{type: Ash.Type.Integer}, _opts, _context) do
    777
  end

  @impl AshRandomParams.Random
  def random(attr_or_arg, opts, context) do
    # Fallback to DefaultRandom for all other types
    AshRandomParams.DefaultRandom.random(attr_or_arg, opts, context)
  end
end
```

## Features

- Automatically generates random values for action accepts and arguments
- Supports custom random value generators
- Useful for testing and development

## Installation

Add `ash_random_params` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_random_params, "~> 0.2.0"}
  ]
end
```

## License

MIT

## Links

- [GitHub Repository](https://github.com/devall-org/ash_random_params)
