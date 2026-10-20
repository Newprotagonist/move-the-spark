require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "create subscribes this device" do
    assert_difference("PushSubscription.count", 1) do
      post push_subscription_path, params: { endpoint: "https://push.example/1", p256dh_key: "p", auth_key: "a" }.to_json,
           headers: { "Content-Type" => "application/json" }
    end
    assert_response :created
    assert_equal @current_user, PushSubscription.sole.user
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

  test "create on an endpoint another user left behind on this device reclaims it for the signed-in user" do
    PushSubscription.create!(user: users(:two), endpoint: "https://push.example/shared-tablet", p256dh_key: "old", auth_key: "old")

    assert_no_difference("PushSubscription.count") do
      post push_subscription_path, params: { endpoint: "https://push.example/shared-tablet", p256dh_key: "new", auth_key: "new" }.to_json,
           headers: { "Content-Type" => "application/json" }
    end

    subscription = PushSubscription.sole
    assert_equal @current_user, subscription.user
    assert_equal "new", subscription.p256dh_key
  end

  test "destroy unsubscribes this device" do
    PushSubscription.create!(user: @current_user, endpoint: "https://push.example/1", p256dh_key: "p", auth_key: "a")

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

  test "destroy does not remove another user's subscription at the same endpoint" do
    PushSubscription.create!(user: users(:two), endpoint: "https://push.example/shared-tablet", p256dh_key: "p", auth_key: "a")

    assert_no_difference("PushSubscription.count") do
      delete push_subscription_path, params: { endpoint: "https://push.example/shared-tablet" }.to_json,
             headers: { "Content-Type" => "application/json" }
    end
    assert_response :no_content
  end

  test "le compte démo ne peut pas s'abonner aux notifications push" do
    demo = User.create!(email_address: "demo@movethespark.app", password: "password", demo: true)
    sign_in_as(demo)

    assert_no_difference("PushSubscription.count") do
      post push_subscription_path, params: { endpoint: "https://push.example/demo", p256dh_key: "p", auth_key: "a" }.to_json,
           headers: { "Content-Type" => "application/json" }
    end
    assert_response :no_content
  end
end
