defmodule Toolex.AMQP.PipelineSubscriberBase do
  use Toolex.AMQP.SubscriberBase, [exchange_name: "inverse.events", exchange_type: :topic]
end
