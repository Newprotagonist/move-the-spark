require "application_system_test_case"

class WeeklyGoalPinningTest < ApplicationSystemTestCase
  test "pinning a weekly goal to a weekday scopes it to that day and lets it be scheduled into the ribbon" do
    travel_to Time.zone.local(2026, 8, 17, 9, 0) do # Monday
      visit root_path

      click_on "+ objectif"
      fill_in "Titre", with: "Yoga"
      choose "Récurrent", allow_label_click: true
      assert_selector "select[name='goal[frequency]']" # waits for the goal-type JS toggle to reveal it
      select "Chaque semaine", from: "Fréquence"
      click_on "mer"
      click_on "Créer"

      visit day_path(date: "2026-08-18") # Tuesday: not the pinned day
      assert_no_text "Yoga"

      visit day_path(date: "2026-08-19") # Wednesday: the pinned day
      assert_text "Yoga"

      find("button[aria-label='Caser dans le ruban']").click
      find("[data-planning-target='placeholder']", match: :first).click

      within("#day-ribbon") { assert_text "Yoga" }
    end
  end
end
