defmodule Toolex.RedixPool do
  defmacro __using__([name: pool_name, otp_app: otp_app]) do
    quote location: :keep do
      @moduledoc false

      use Supervisor
      use Toolex.BasePool,
        max_overflow: 10,
        pool_name: unquote(pool_name),
        otp_app: unquote(otp_app),
        size: 20,
        strategy: :lifo,
        worker_args: redis_url(),
        worker_module: Redix

      def command(command, _retry \\ 0) do
        exec  &Redix.command(&1, command)
      end
      def command!(command, _retry \\ 0) do
        exec  &Redix.command!(&1, command)
      end

      def pipeline(commands, options \\ [])
      def pipeline(commands, transaction: true) do
        pipeline [ ~w(MULTI) | commands] ++ [ ~w(EXEC) ]
      end
      def pipeline(commands, _options) do
        exec &Redix.pipeline(&1, commands)
      end

      def pipeline!(commands, options \\ [])
      def pipeline!(commands, transaction: true) do
        pipeline! [ ~w(MULTI) | commands] ++ [ ~w(EXEC) ]
      end
      def pipeline!(commands, _options) do
        (&Redix.pipeline!(&1, commands))
        |> exec()
        |> Enum.map(&possibly_raise/1)
      end

      defp exec(fun) do
        ExStatsD.counter 1, "webapp.db.query_count"
        ExStatsD.timing "webapp.db.query_exec_time", fn ->
          :poolboy.transaction(unquote(pool_name), fun)
        end
      end

      defp redis_url do
        case Application.get_env(unquote(otp_app), __MODULE__) do
          [redis_url: redis_url] -> redis_url
          _other                  ->
            raise """
            Missing :redis_url configuration.
            Please add
            config #{unquote(otp_app)}, #{__MODULE__}, redis_url: <url>
            to your config/config.exs.
            """
        end
      end

      defp possibly_raise(%Redix.Error{} = error), do: raise error
      defp possibly_raise(other),                  do: other
    end
  end
end
