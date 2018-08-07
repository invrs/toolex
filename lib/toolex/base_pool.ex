defmodule Toolex.BasePool do
  defmacro __using__([
    max_overflow: max_overflow,
    pool_name: pool_name,
    retry_limit: retry_limit,
    size: size,
    strategy: strategy,
    worker_args: worker_args,
    worker_module: worker_module
  ])
  do
    quote location: :keep do
      @moduledoc false

      use Supervisor
      require Logger

      def exec(fun) do
        :poolboy.transaction unquote(pool_name), fun
      end

      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, [], opts)
      end

      def init([]) do
        pool_opts = [
          max_overflow: unquote(max_overflow),
          name: {:local, unquote(pool_name)},
          strategy: unquote(strategy),
          size: unquote(size),
          worker_module: unquote(worker_module)
        ]

        children = [
          :poolboy.child_spec(unquote(pool_name), pool_opts, unquote(worker_args))
        ]

        supervise(children, strategy: :one_for_one, name: __MODULE__)
      end
    end
  end
end
