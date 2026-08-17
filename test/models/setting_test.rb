require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "instance lazily creates the singleton row with defaults" do
    assert_equal 0, Setting.count
    setting = Setting.instance
    assert_equal 1, Setting.count
    assert_equal 10, setting.points_per_goal
    assert_equal 30, setting.default_appointment_lead_minutes
  end

  test "instance returns the same row on subsequent calls" do
    first = Setting.instance
    second = Setting.instance
    assert_equal first.id, second.id
    assert_equal 1, Setting.count
  end
end
