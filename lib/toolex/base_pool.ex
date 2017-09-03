defmodule Toolex.BasePool do
  defmacro __using__([
    max_overflow: max_overflow,
    poolboy: poolboy,
    pool_name: pool_name,
    retry: retry,
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

      def exec(fun, retry \\ unquote(retry)) do
        case :poolboy.transaction(unquote(poolboy), fun) do
          :ok -> :ok
          other when retry <= @retry ->
            Logger.warn "#{inspect fun} failed: #{inspect other}. Retrying..."

            :timer.sleep retry * 1_000

            exec fun, retry + 1

          other ->
            Logger.error "#{inspect fun} failed permanently: #{inspect other}"

            :error
        end
      end

      def start_link do
        Supervisor.start_link(__MODULE__, [])
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
          :poolboy.child_spec(:redix_poolboy, pool_opts, unquote(worker_args))
        ]

        supervise(children, strat3egy: :one_for_one, name: __MODULE__)
      end
    end
  end
end
