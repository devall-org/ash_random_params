# Rules for working with AshRandomParams

AshRandomParams generates random parameters for Ash resource actions. Useful for test data generation.

## Setup

```elixir
defmodule MyApp.Post do
  use Ash.Resource, extensions: [AshRandomParams]

  random_params do
    random MyRandom  # Optional: custom generator
  end
end
```

## Basic Usage

```elixir
# Generate random params
Post.random_params!(:create)

# With initial params
Post.random_params!(:create, %{author: "James"})

# With options
Post.random_params!(:create, %{}, %{
  enforce_random: [:content],    # Force random generation
  exclude: [:title],             # Skip generation
  include_defaults?: false       # Exclude defaults
})
```

## Default Behavior

Generates random values only for accepts/arguments with `allow_nil?: false` and `default == nil`.

For `belongs_to` relationship foreign keys:
- `create` actions: generated as `nil`
- Other actions: not generated (preserves existing relationship)

## Custom Random Generator

```elixir
defmodule MyRandom do
  use AshRandomParams.Random

  @impl true
  def random(%{type: Ash.Type.Integer}, _opts, _context) do
    777
  end

  @impl true
  def random(attr_or_arg, opts, context) do
    # Fallback to DefaultRandom for other types
    AshRandomParams.DefaultRandom.random(attr_or_arg, opts, context)
  end
end
```

## Options

- **enforce_random**: Force random generation for specific fields
- **exclude**: Skip generation for specific fields
- **include_defaults?**: Include fields with `allow_nil?: true` or non-nil defaults (default: `true`)

## Testing

```elixir
test "create post" do
  params = Post.random_params!(:create, %{author: "Test Author"})
  assert {:ok, post} = MyApp.Blog.create_post(params)
end
```

