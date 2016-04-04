defmodule Toolex.AMQP.SubscriberSupervisor do
  alias Toolex.AMQP.SubscriberBase
  use Supervisor

  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init([]) do
    case AMQP.Connection.open(rabbitmq_url) do
      {:error, reason}  -> {:stop, "Can't connect: #{inspect reason}"}
      {:ok, connection} ->
        children =
          children
          |> Enum.map(&Map.put(&1, :connection, connection))
          |> Enum.map(&worker(SubscriberBase, [&1], id: &1.module))

        supervise children, strategy: :one_for_one
    end
  end

  defp rabbitmq_url do
    Application.get_env(:toolex, :rabbitmq_url)
  end

  defp children do
    Application.get_env(:toolex, :subscribers)
    |> Enum.map(&struct(SubscriberBase, &1))
  end
end
