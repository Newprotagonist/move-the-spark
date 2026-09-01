require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:body)

  test "requires endpoint, p256dh_key, auth_key" do
    subscription = PushSubscription.new
    assert_not subscription.valid?
    assert_includes subscription.errors.attribute_names, :endpoint
    assert_includes subscription.errors.attribute_names, :p256dh_key
    assert_includes subscription.errors.attribute_names, :auth_key
  end

  test "endpoint must be unique" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    dup = PushSubscription.new(endpoint: "https://push.example/1", p256dh_key: "c", auth_key: "d")
    assert_not dup.valid?
  end

  test "deliver calls Webpush.payload_send with the subscription's keys and VAPID credentials" do
    subscription = PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "p256dh", auth_key: "auth")

    called_with = nil
    Webpush.stub(:payload_send, ->(**kwargs) { called_with = kwargs }) do
      subscription.deliver({ title: "Hi" }.to_json)
    end

    assert_equal "https://push.example/1", called_with[:endpoint]
    assert_equal "p256dh", called_with[:p256dh]
    assert_equal "auth", called_with[:auth]
    assert called_with[:vapid][:public_key].present?
    assert called_with[:vapid][:private_key].present?
  end

  test "deliver destroys the subscription when the push service reports it gone (404/410)" do
    subscription = PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "p256dh", auth_key: "auth")

    Webpush.stub(:payload_send, ->(**kwargs) { raise Webpush::ExpiredSubscription.new(FakeResponse.new(""), "push.example") }) do
      subscription.deliver("{}")
    end

    assert_not PushSubscription.exists?(subscription.id)
  end

  test "broadcast delivers to every subscription" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    PushSubscription.create!(endpoint: "https://push.example/2", p256dh_key: "c", auth_key: "d")

    delivered_to = []
    Webpush.stub(:payload_send, ->(**kwargs) { delivered_to << kwargs[:endpoint] }) do
      PushSubscription.broadcast(title: "Titre", body: "Corps")
    end

    assert_equal [ "https://push.example/1", "https://push.example/2" ], delivered_to.sort
  end

  test "broadcast includes the app icon and a monochrome badge so the notification shows the real logo" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")

    sent_message = nil
    Webpush.stub(:payload_send, ->(**kwargs) { sent_message = kwargs[:message] }) do
      PushSubscription.broadcast(title: "Titre", body: "Corps", path: "/moi")
    end

    options = JSON.parse(sent_message)["options"]
    assert_equal "/icon-192.png?v=#{ApplicationHelper::ICON_VERSION}", options["icon"]
    assert_equal "/badge-96.png?v=#{ApplicationHelper::ICON_VERSION}", options["badge"]
    assert_equal "/moi", options["data"]["path"]
  end
end
