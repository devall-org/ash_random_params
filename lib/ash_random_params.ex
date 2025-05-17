defmodule AshRandomParams do
  @random_params %Spark.Dsl.Section{
    name: :random_params,
    describe: """
    random_params configuration
    """,
    schema: [
      random: [
        type:
          {:spark_function_behaviour, AshRandomParams.Random, {AshRandomParams.RandomFunction, 4}},
        required: false,
        default: {AshRandomParams.DefaultRandom, []},
        doc: """
        random attribute, argument generation function
        """
      ]
    ],
    examples: [
      """
      random_params do
        random MyRandom
      end
      """
    ],
    entities: []
  }

  use Spark.Dsl.Extension,
    sections: [@random_params],
    transformers: [AshRandomParams.Transformer]
end
