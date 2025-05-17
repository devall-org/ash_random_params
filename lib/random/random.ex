defmodule AshRandomParams.Random do
  @callback random(
              attr_or_arg :: Ash.Resource.Attribute.t() | Ash.Resource.Actions.Argument.t(),
              opts :: keyword(),
              context :: map()
            ) :: term()

  defmacro __using__(_) do
    quote do
      @behaviour AshRandomParams.Random
    end
  end
end
