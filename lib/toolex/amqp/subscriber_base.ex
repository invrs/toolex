defmodule Toolex.AMQP.SubscriberBase do
  use GenServer
  require Logger

  defstruct module: nil, queue_name: nil, arguments: nil, channel: nil,
            connection: nil

  @subscribers    []
  @exchange       "inverse.headers"
  @prefetch_count 5

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
          metadata:
            Map.update(meta, :headers, [], fn
              (headers) -> Enum.map(headers, &Tuple.to_list/1)
            end)
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
    queue_name = module_to_queue_name state.module

    case AMQP.Channel.open(state.connection) do
      {:error, reason} -> {:stop, "Can't open channel: #{inspect reason}"}
      {:ok, channel}   ->
        AMQP.Basic.qos(channel, prefetch_count: @prefetch_count)
        AMQP.Queue.declare(channel, queue_name, durable: true)
        AMQP.Exchange.declare(channel, @exchange, :headers, durable: true)
        AMQP.Queue.unbind(channel, queue_name, @exchange)
        AMQP.Queue.bind(channel, queue_name, @exchange, arguments: state.arguments)
        AMQP.Basic.consume(channel, queue_name, self)

        {:ok, %{state | channel: channel}}
    end
  end

  defp module_to_queue_name(module) do
    module
    |> Macro.underscore
    |> String.replace(~r/[^a-z]/, "-")
  end

  def terminate(_reason, state) do
    IO.inspect state
    #AMQP.Channel.close channel
    #AMQP.Connection.close channel.conn
    :ok
  end
end
