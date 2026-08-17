require "application_system_test_case"

class ShoppingListsTest < ApplicationSystemTestCase
  test "creating a list, adding an item, and checking it off" do
    visit shopping_lists_path

    click_on "+ Liste"
    fill_in "Nom de la liste", with: "Courses hebdo"
    click_on "Créer"

    assert_text "Courses hebdo"

    fill_in "Ajouter un article…", with: "Pommes"
    click_on "Ajouter"

    assert_text "Pommes"

    within(first("div", text: "Pommes")) { find("input[type=checkbox]").check }

    assert_selector "span.line-through", text: "Pommes"
  end
end
