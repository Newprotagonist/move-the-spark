require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "reset_demo_content! refuse un compte non marqué démo" do
    user = User.create!(email_address: "not-demo@example.com", password: "password")
    assert_raises(RuntimeError) { user.reset_demo_content! }
  end

  test "reset_demo_content! recrée le même jeu de démonstration et purge les abonnements push" do
    user = User.create!(email_address: "demo@movethespark.app", password: "password", demo: true)
    user.push_subscriptions.create!(endpoint: "https://push.example/stale", p256dh_key: "a", auth_key: "b")
    Goal.create!(user: user, title: "Fouillis d'un visiteur", recurring: false, scheduled_on: Date.current)

    user.reset_demo_content!

    assert_equal [ "Faire les courses", "Lire 20 minutes", "Méditer", "Sport" ], user.goals.reload.pluck(:title).sort
    assert_equal 1, user.appointments.reload.count
    assert_empty user.push_subscriptions.reload
  end
end
