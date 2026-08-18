require "application_system_test_case"

class UnscheduleGoalTest < ApplicationSystemTestCase
  test "removing a goal from its hour slot via the checklist badge's x button" do
    Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.current, scheduled_hour: 9)

    visit root_path
    within("#day-ribbon") { assert_text "Sport" }
    assert_text "09:00"

    find("button[aria-label='Retirer du ruban']").click

    within("#day-ribbon") { assert_no_text "Sport" }
    assert_no_text "09:00"
    goal = Goal.find_by(title: "Sport")
    assert_nil goal.scheduled_hour
  end
end
