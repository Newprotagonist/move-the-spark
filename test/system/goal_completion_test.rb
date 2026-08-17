require "application_system_test_case"

class GoalCompletionTest < ApplicationSystemTestCase
  test "creating a daily goal and completing it updates points and streak" do
    visit root_path

    click_on "+ objectif"
    fill_in "Titre", with: "Lire 20 minutes"
    choose "Récurrent", allow_label_click: true
    select "Chaque jour", from: "Fréquence"
    click_on "Créer"

    assert_text "Lire 20 minutes"
    assert_text "⭐ 0"
    assert_text "🔥 0"

    click_button "Marquer comme fait"

    assert_text "Lire 20 minutes"
    assert_text "⭐ 10"
    assert_text "🔥 1"
  end
end
