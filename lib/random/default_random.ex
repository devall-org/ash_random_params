defmodule AshRandomParams.DefaultRandom do
  use AshRandomParams.Random

  # Array
  def random(
        %{type: {:array, type}, constraints: constraints, name: name},
        _opts,
        %{random: {random_mod, random_opts}} = context
      ) do
    min_length = constraints |> Keyword.get(:min_length, 0)

    1..min_length//1
    |> Enum.map(fn _ ->
      random_mod.random(%{type: type, name: name}, random_opts, context)
    end)
  end

  # One of atoms
  def random(%{type: Ash.Type.Atom, constraints: constraints}, _opts, _context) do
    constraints |> Keyword.fetch!(:one_of) |> Enum.random()
  end

  def random(%{type: Ash.Type.Integer}, _opts, _context), do: random_int()

  def random(%{type: Ash.Type.Decimal}, _opts, _context),
    do: Decimal.new("#{random_int()}.#{random_int()}")

  def random(%{type: Ash.Type.Boolean}, _opts, _context), do: [true, false] |> Enum.random()
  def random(%{type: Ash.Type.Map}, _opts, _context), do: %{}

  def random(%{type: Ash.Type.Date}, _opts, _context),
    do: random_date_time() |> DateTime.to_date()

  def random(%{type: Ash.Type.UtcDatetime}, _opts, _context), do: random_date_time()
  def random(%{type: Ash.Type.UtcDatetimeUsec}, _opts, _context), do: random_date_time()
  def random(%{type: Ash.Type.DateTime}, _opts, _context), do: random_date_time()

  def random(%{type: Ash.Type.String, name: name}, _opts, _context),
    do: "#{name}-#{random_int()}"

  def random(%{type: Ash.Type.CiString, name: name}, _opts, _context),
    do: "#{name}-#{random_int()}"

  def random(%{name: name, type: type} = attr_or_arg, opts, context) do
    {attr_or_arg, opts, context} |> dbg()
    raise "Cannot make random value for name: #{name}, type: #{type}"
  end

  # Private

  @year_seconds 365 * 24 * 60 * 60

  defp random_date_time() do
    DateTime.utc_now()
    |> DateTime.add(:rand.uniform(20 * @year_seconds) - 10 * @year_seconds, :second)
  end

  defp random_int() do
    :rand.uniform(1_000_000_000_000)
  end
end
