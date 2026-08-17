require "application_system_test_case"

class FocusModeTest < ApplicationSystemTestCase
  test "starting focus, then finishing, completes the goal and returns to the day" do
    Goal.create!(title: "Lire", recurring: true, frequency: "daily", active_from: Date.current)

    visit root_path
    click_link "Démarrer le focus"

    assert_text "Lire"
    assert_text "Terminé"
    assert_selector "[data-timer-target='display']"

    click_on "Terminé"

    assert_current_path day_path(date: Date.current)
    goal = Goal.find_by(title: "Lire")
    assert goal.goal_completions.exists?
  end

  test "closing without saving does not complete the goal" do
    Goal.create!(title: "Lire", recurring: true, frequency: "daily", active_from: Date.current)

    visit root_path
    click_link "Démarrer le focus"
    click_on "Fermer sans enregistrer"

    assert_current_path day_path(date: Date.current)
    goal = Goal.find_by(title: "Lire")
    assert_not goal.goal_completions.exists?
    assert_not goal.reload.timer_running?
  end
end
