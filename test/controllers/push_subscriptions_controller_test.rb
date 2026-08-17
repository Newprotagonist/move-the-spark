require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "create subscribes this device" do
    assert_difference("PushSubscription.count", 1) do
      post push_subscription_path, params: { endpoint: "https://push.example/1", p256dh_key: "p", auth_key: "a" }.to_json,
           headers: { "Content-Type" => "application/json" }
    end
    assert_response :created
  end

  test "create is idempotent for the same endpoint" do
    post push_subscription_path, params: { endpoint: "https://push.example/1", p256dh_key: "p", auth_key: "a" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_no_difference("PushSubscription.count") do
      post push_subscription_path, params: { endpoint: "https://push.example/1", p256dh_key: "p2", auth_key: "a2" }.to_json,
           headers: { "Content-Type" => "application/json" }
    end
    assert_equal "p2", PushSubscription.sole.p256dh_key
  end

  test "destroy unsubscribes this device" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "p", auth_key: "a")

    assert_difference("PushSubscription.count", -1) do
      delete push_subscription_path, params: { endpoint: "https://push.example/1" }.to_json,
             headers: { "Content-Type" => "application/json" }
    end
    assert_response :no_content
  end

  test "destroy is a no-op for an unknown endpoint" do
    assert_no_difference("PushSubscription.count") do
      delete push_subscription_path, params: { endpoint: "https://unknown" }.to_json,
             headers: { "Content-Type" => "application/json" }
    end
    assert_response :no_content
  end
end
