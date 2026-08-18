require "application_system_test_case"

class ArchiveGoalTest < ApplicationSystemTestCase
  test "archiving a recurring goal removes it from the day view and lists it as archived" do
    Goal.create!(title: "Vieux rituel", recurring: true, frequency: "daily", active_from: Date.current - 10)

    visit root_path
    assert_text "Vieux rituel"

    click_link "Modifier"
    accept_confirm { click_on "Archiver" }

    assert_no_text "Vieux rituel"

    visit profile_path
    click_on "Objectifs archivés"
    assert_text "Vieux rituel"

    click_on "Réactiver"
    visit root_path
    assert_text "Vieux rituel"
  end
end
