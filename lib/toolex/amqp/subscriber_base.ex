defmodule Toolex.AMQP.SubscriberBase do

  defstruct module: nil, bind_opts: nil, channel: nil, connection: nil

  defmacro __using__([exchange_name: exchange_name, exchange_type: exchange_type]) do
    quote do
      use GenServer
      use AMQP
      require Logger

      @prefetch_count 10

      # Server, state is the attached handler
      def start_link(state) do
        GenServer.start_link(__MODULE__, state, name: state.module)
      end

      def handle_info({:basic_deliver, payload, meta}, state) do
        Logger.info "Deliver received for #{state.module}"

        try do
          payload = Poison.decode!(payload)
          apply state.module, :handle, [payload, meta]
          AMQP.Basic.ack state.channel, meta.delivery_tag
        rescue
          reason ->
            payload =
              case Poison.decode payload do
                {:ok, hash}     -> hash
                {:error, error} -> "Decode error: #{error}, #{payload}"
              end

            metadata = %{
              payload: payload,
              metadata: update_metadata(meta)
            }

            Toolex.ErrorReporter.report reason, metadata, "AMQP.SubscriberBase/#{state.module}"

            Logger.error "Subscriber failed: #{state.module}"
            Logger.error "Exception: #{inspect reason}"
            Logger.error "First attempt: #{inspect !meta.redelivered}"

            AMQP.Basic.reject state.channel, meta.delivery_tag, requeue: !meta.redelivered
        end

        {:noreply, state}
      end

      def handle_info({:basic_consume_ok, _meta}, state), do: {:noreply, state}

      def handle_info({event, meta}, state) do
        Logger.info "received event: #{inspect event}"
        Logger.info "#{inspect meta}"

        {:noreply, state}
      end

      def handle_call(msg, _from, state) do
        Logger.info "received call: #{inspect msg}"
        {:noreply, state}
      end

      def init(state) do
        queue_name    = module_to_queue_name state.module
        exchange_name = unquote(exchange_name)
        exchange_type = unquote(exchange_type)

        case AMQP.Channel.open(state.connection) do
          {:error, reason} -> {:stop, "Can't open channel: #{inspect reason}"}
          {:ok, channel}   ->
            AMQP.Basic.qos(channel, prefetch_count: @prefetch_count)
            AMQP.Queue.declare(channel, queue_name, durable: true)
            AMQP.Exchange.declare(channel, exchange_name, exchange_type, durable: true)
            AMQP.Queue.unbind(channel, queue_name, exchange_name)
            AMQP.Queue.bind(channel, queue_name, exchange_name, state.bind_opts)
            AMQP.Basic.consume(channel, queue_name, self())

            {:ok, %{state | channel: channel}}
        end
      end

      defp module_to_queue_name(module) do
        module
        |> Macro.underscore
        |> String.replace(~r/[^a-z]/, "-")
      end

      defp update_metadata(metadata) when is_map(metadata) do
        Map.update(metadata, :headers, [], &update_meta_headers/1)
      end
      defp update_metadata(metadata), do: metadata

      defp update_meta_headers(headers) when is_list(headers) do
        IO.puts("UPDATING META HEADERS (is list): (#{inspect(headers)})")
        IO.inspect(headers)
        Enum.map headers, &Tuple.to_list/1
      end
      defp update_meta_headers(_), do: []

      def terminate(_reason, state) do
        "Terminating channel #{inspect state.channel} on " <>
        "connection #{inspect state.connection}..."
        |> Logger.info()

        AMQP.Channel.close state.channel

        :ok
      end
    end
  end
end
