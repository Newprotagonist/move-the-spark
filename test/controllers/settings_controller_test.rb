require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "shows the settings form with current values" do
    Setting.instance.update!(points_per_goal: 20)

    get edit_settings_path

    assert_response :success
    assert_select "input[name='setting[points_per_goal]'][value='20']"
  end

  test "updates the settings" do
    patch settings_path, params: { setting: { points_per_goal: 5, default_appointment_lead_minutes: 15, daily_goal_reminder_time: "19:30" } }

    assert_redirected_to edit_settings_path
    setting = Setting.instance
    assert_equal 5, setting.points_per_goal
    assert_equal 15, setting.default_appointment_lead_minutes
  end

  test "invalid settings re-render the form" do
    patch settings_path, params: { setting: { points_per_goal: -1 } }
    assert_response :unprocessable_entity
  end

  test "changing points_per_goal affects future completions, not past ones" do
    goal = Goal.create!(title: "Habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post complete_goal_path(goal), params: { occurred_on: "2026-08-16" }
    assert_equal 10, goal.goal_completions.sole.points_awarded

    patch settings_path, params: { setting: { points_per_goal: 50 } }
    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    assert_equal 10, goal.goal_completions.find_by(occurred_on: "2026-08-16").points_awarded
    assert_equal 50, goal.goal_completions.find_by(occurred_on: "2026-08-17").points_awarded
  end
end
