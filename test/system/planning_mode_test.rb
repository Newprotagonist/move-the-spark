require "application_system_test_case"

class PlanningModeTest < ApplicationSystemTestCase
  test "placing a goal into an hour slot shows it in the ribbon" do
    Goal.create!(title: "Lire", recurring: true, frequency: "daily", active_from: Date.current)

    visit root_path
    assert_text "Lire"

    find("button[aria-label='Caser dans le ruban']").click
    assert_text "Touche un créneau"

    find("[data-planning-target='placeholder']", match: :first).click

    assert_no_text "Touche un créneau"
    goal = Goal.find_by(title: "Lire")
    assert_not_nil goal.scheduled_hour
    within("#day-ribbon") { assert_text "Lire" }
  end
end
