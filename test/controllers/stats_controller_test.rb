require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "renders successfully with no goals at all" do
    get stats_path

    assert_response :success
    assert_select "body", text: /Pas encore assez d.historique/
  end

  test "renders successfully with a realistic mix of daily, weekly, one-off, and archived goals" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      daily = Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.current - 6)
      4.times { |i| GoalCompletion.create!(goal: daily, occurred_on: Date.current - i, completed_at: Time.current, points_awarded: 10) }

      weekly = Goal.create!(title: "Bilan", recurring: true, frequency: "weekly", active_from: Date.current - 21)
      GoalCompletion.create!(goal: weekly, occurred_on: Date.current.beginning_of_week, completed_at: Time.current, points_awarded: 10)

      Goal.create!(title: "Buy milk", recurring: false, scheduled_on: Date.current)

      archived = Goal.create!(title: "Old habit", recurring: true, frequency: "daily", active_from: Date.current - 10,
                               archived_at: Date.current - 1)
      GoalCompletion.create!(goal: archived, occurred_on: Date.current - 5, completed_at: Time.current, points_awarded: 10)

      get stats_path

      assert_response :success
      assert_select "body", text: /Sport/
      assert_select "body", text: /Taux de complétion global/
      assert_select "body", text: /meilleur jour/
    end
  end
end
