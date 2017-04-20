defmodule Toolex.AMQP.Supervisor do
  defmacro __using__([otp_app: otp_app, subscriber_module: subscriber_module]) do
    quote do
      import Toolex.AMQP.Supervisor

      use Supervisor

      @subscriber_module unquote(subscriber_module)

      Module.register_attribute(__MODULE__, :subscribers, accumulate: true)

      def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

      defp rabbitmq_url do
        Application.get_env(unquote(otp_app), __MODULE__)[:rabbitmq_url]
      end
    end
  end

  defmacro supervise(block) do
    quote do
      try do
        unquote(block)
      after
        :ok
      end

      def init([]) do
        case AMQP.Connection.open(rabbitmq_url()) do
          {:error, reason}  -> {:stop, "Can't connect: #{inspect reason}"}
          {:ok, connection} ->
            children =
              @subscribers
              |> Enum.map(&Map.put(&1, :connection, connection))
              |> Enum.map(&worker(@subscriber_module, [&1], id: &1.module))

            supervise children, strategy: :one_for_one
        end
      end
    end
  end

  defmacro subscribe(module, bind_opts) do
    quote do
      spec = %Toolex.AMQP.SubscriberBase{
        module: unquote(module),
        bind_opts: unquote(bind_opts)
      }

      Module.put_attribute __MODULE__, :subscribers, spec
    end
  end
end
