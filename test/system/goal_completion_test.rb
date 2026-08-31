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
    within "#gamification-summary" do
      assert_text(/0\s*0/)
    end

    click_button "Marquer comme fait"

    assert_text "Lire 20 minutes"
    # 10 points + a 1-point streak bonus: this completion is what grows the
    # streak from 0 to 1.
    within "#gamification-summary" do
      assert_text(/11\s*1/)
    end
  end
end
