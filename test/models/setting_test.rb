require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "instance lazily creates the singleton row with defaults" do
    assert_equal 0, Setting.count
    setting = Setting.instance
    assert_equal 1, Setting.count
    assert_equal 10, setting.points_per_goal
    assert_equal 30, setting.default_appointment_lead_minutes
    assert_equal 10, setting.streak_bonus_cap
  end

  test "streak_bonus_cap must be zero or greater" do
    setting = Setting.instance
    setting.streak_bonus_cap = -1
    assert_not setting.valid?

    setting.streak_bonus_cap = 0
    assert setting.valid?
  end

  test "instance returns the same row on subsequent calls" do
    first = Setting.instance
    second = Setting.instance
    assert_equal first.id, second.id
    assert_equal 1, Setting.count
  end
end
