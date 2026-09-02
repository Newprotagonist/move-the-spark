require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "shows points, level, streak, and heatmap" do
    goal = Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.current - 3)
    GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, duration_seconds: 900, points_awarded: 240)

    get profile_path

    assert_response :success
    assert_select "body", text: /240/
    assert_select "body", text: /niv\. 3/
    assert_select "body", text: /5 dernières semaines/
  end

  test "focus hours only count completions from the current week" do
    goal = Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.current - 10)
    travel_to Date.current.beginning_of_week.beginning_of_day + 1.day do
      GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, duration_seconds: 3600, points_awarded: 10)
    end
    travel_to (Date.current.beginning_of_week - 7).beginning_of_day + 1.day do
      GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, duration_seconds: 7200, points_awarded: 10)
    end

    get profile_path

    assert_response :success
    assert_select "body", text: /1\.0/
  end
end
