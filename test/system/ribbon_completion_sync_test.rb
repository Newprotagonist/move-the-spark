require "application_system_test_case"

class RibbonCompletionSyncTest < ApplicationSystemTestCase
  test "checking off a scheduled goal updates its ribbon card too, without a reload" do
    Goal.create!(user: @current_user, title: "Sport", recurring: true, frequency: "daily", active_from: Date.current, scheduled_hour: 9)

    visit root_path
    within("#day-ribbon") { assert_no_selector "span.line-through" }

    find("button[aria-label='Marquer comme fait']").click

    within("#day-ribbon") { assert_selector "span.line-through", text: "Sport" }
  end
end
