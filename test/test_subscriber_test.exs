defmodule Toolex.TestSubscriberTest do

  use ExUnit.Case

  @payload {:basic_deliver, "{\"tag\":\"td.events_production.tests\",\"data\":{\"visit_id\":\"\",\"userAgent\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36\",\"urlPath\":\"\",\"urlParameters\":{\"\":true},\"time\":1533706286,\"sessionId\":\"d2bdec51-79dc-44c7-98fe-e8c02bf1505f\",\"reward\":0,\"referrer\":\"\",\"productSub\":\"20030107\",\"platform\":\"Win32\",\"params\":{\"video\":false,\"tests\":{\"newsletter_overlay_cta_science-innovation_musk-reads_musk-reads\":{\"text\":\"We need your help to build a smarter world. Explore the science that will shape tomorrow by signing up for our daily newsletter.\"},\"newsletter_overlay_author_text_v3\":{\"widget\":\"50-nick-lucchesi\",\"text\":\"Inverse is fueling the next generation of dreamers and doers by reporting the wonder of the world in a new light.\"},\"newsletter_modal_design\":{\"widget\":\"white_no_cta\"},\"commerce_cta_button_discount\":{\"widget\":\"off\"}},\"section\":\"Innovation\",\"promo\":\"newsletter-overlay\",\"primary_label\":\"Tesla\",\"labels\":[\"Elon Musk\",\"Internet Culture\",\"Twitter\",\"Weed\",\"Explainer\",\"Standard\"],\"exit_intent\":true,\"bookmark\":{\"stream_index\":0,\"seen\":3,\"pages\":2,\"page\":2},\"article_url\":\"https://www.inverse.com/article/47863-is-elon-musk-taking-tesla-private\",\"article\":\"973d3e0e-19af-446c-9751-419a2334c7d9\"},\"name\":\"newsletter_overlay_cta_science-innovation_musk-reads_musk-reads\",\"maxTouchPoints\":\"\",\"languages\":[\"en-US\",\"en\"],\"language\":\"en-US\",\"label\":\"white_no_cta\",\"javaEnabled\":\"\",\"ip\":\"\",\"innerWidth\":1536,\"innerHeight\":691,\"hardwareConcurrency\":4,\"doNotTrack\":\"1\",\"device\":\"desktop\",\"cookieEnabled\":true,\"arm\":6,\"appVersion\":\"5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36\",\"appName\":\"Netscape\",\"appCodeName\":\"Mozilla\"}}", %{app_id: :undefined, cluster_id: :undefined, consumer_tag: "amq.ctag-hDI6nswA8jZCf_Vzp_t_mA", content_encoding: :undefined, content_type: :undefined, correlation_id: :undefined, delivery_tag: 1, exchange: "inverse.events", expiration: :undefined, headers: :undefined, message_id: :undefined, persistent: false, priority: :undefined, redelivered: true, reply_to: :undefined, routing_key: "td.events_production.tests", timestamp: :undefined, type: :undefined, user_id: :undefined}}

  test "handles erroneous message" do
    Toolex.TestSubscriber.handle_info(@payload, %{})
  end
end

defmodule Toolex.TestSubscriber do
  use Toolex.AMQP.SubscriberBase, exchange_name: "direct", exchange_name: "inverse.events"
end
