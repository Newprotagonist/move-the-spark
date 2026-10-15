require "application_system_test_case"

class PlanningChecklistBadgeTest < ApplicationSystemTestCase
  test "scheduling a goal shows the HH:00 badge on its checklist row without a reload" do
    Goal.create!(user: @current_user, title: "Lire", recurring: true, frequency: "daily", active_from: Date.current)

    visit root_path
    find("button[aria-label='Caser dans le ruban']").click
    find("[data-planning-target='placeholder']", match: :first).click

    within("#day-ribbon") { assert_text "Lire" }

    # The checklist row is a separate DOM location from the ribbon — this is
    # the bug: only the ribbon used to refresh, leaving this stale.
    within("[data-controller='planning']") { assert_text(/\d\d:00/) }
  end
end
