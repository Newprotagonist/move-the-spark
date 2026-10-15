require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "a setting row is created automatically when a user is created" do
    user = User.create!(email_address: "new@example.com", password: "password")
    assert user.setting.present?
    assert_equal 10, user.setting.points_per_goal
    assert_equal 30, user.setting.default_appointment_lead_minutes
    assert_equal 10, user.setting.streak_bonus_cap
  end

  test "streak_bonus_cap must be zero or greater" do
    setting = users(:one).setting
    setting.streak_bonus_cap = -1
    assert_not setting.valid?

    setting.streak_bonus_cap = 0
    assert setting.valid?
  end

  test "a user can only have one setting row" do
    duplicate = Setting.new(user: users(:one), points_per_goal: 5, default_appointment_lead_minutes: 10,
                             daily_goal_reminder_time: "18:00", streak_bonus_cap: 0)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "est déjà utilisé"
  end

  test "two users' settings are independent" do
    one = users(:one).setting
    two = users(:two).setting

    one.update!(points_per_goal: 25)

    assert_equal 25, one.reload.points_per_goal
    assert_equal 10, two.reload.points_per_goal
  end
end
