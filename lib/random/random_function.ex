defmodule AshRandomParams.RandomFunction do
  @moduledoc false
  use AshRandomParams.Random

  def random(attr_or_arg, [fun: {m, f, args}], context) do
    apply(m, f, [attr_or_arg, context] ++ args)
  end

  def random(attr_or_arg, [fun: fun], context) do
    fun.(attr_or_arg, context)
  end
end
