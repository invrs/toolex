defmodule Toolex.AMQP.PubSubSubscriberBase do
  use Toolex.AMQP.SubscriberBase, [exchange_name: "inverse.headers", exchange_type: :headers]
end
