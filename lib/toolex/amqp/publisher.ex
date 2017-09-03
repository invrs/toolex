defmodule Toolex.AMQP.Publisher do
  defmacro __using__([exchange: exchange, otp_app: otp_app]) do
    quote location: :keep do
      use GenServer
      use AMQP

      def publish(pid, tag, payload) do
        GenServer.cast pid, {:publish, tag, payload}
      end

      def handle_cast({:publish, tag, data}, channel) do
        payload = Poison.encode! %{tag: tag, data: data}

        Basic.publish channel, unquote(exchange), tag, payload

        {:noreply, channel}
      end

      def start_link(opts \\ []) do
        GenServer.start_link __MODULE__, :ok, opts
      end

      def init(:ok) do
        with {:ok, connection} <- Connection.open(rabbitmq_url()),
             {:ok, channel}    <- Channel.open(connection)
        do
          {:ok, channel}
        else
          {:error, reason} ->
            {:stop, "AMQP startup failed: #{inspect reason}"}
        end
      end

      def terminate(reason, channel) do
        Logger.info "Terminating channel #{inspect channel}: #{inspect reason}"

        Channel.close(channel)
        Connection.close(channel.conn)

        :ok
      end

      defp rabbitmq_url do
        case Application.get_env(unquote(otp_app), __MODULE__) do
          [rabbitmq_url: rabbitmq_url] -> rabbitmq_url
          _other                       ->
            raise """
            Missing :rabbitmq_url configuration.
            Please add
            config #{unquote(otp_app)}, #{__MODULE__}, rabbitmq_url: <url>
            to your config/config.exs.
            """
        end
      end
    end
  end
end
