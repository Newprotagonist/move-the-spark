require "application_system_test_case"

class GoalHistoryTest < ApplicationSystemTestCase
  test "viewing a goal's history from its edit sheet shows completion and duration data" do
    goal = Goal.create!(title: "Course à pied", recurring: true, frequency: "daily", active_from: Date.current - 2, timed: true)
    GoalCompletion.create!(goal: goal, occurred_on: Date.current - 2, completed_at: Time.current, duration_seconds: 900, points_awarded: 10)
    GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, duration_seconds: 1200, points_awarded: 10)

    visit root_path
    click_link "Modifier"
    click_link "Voir l’historique"

    assert_text "Course à pied"
    assert_text "complétions"
    assert_text "min en moyenne"
    assert_text "DURÉE DANS LE TEMPS"
  end
end
