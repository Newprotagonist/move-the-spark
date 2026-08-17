require "test_helper"

class DaysControllerTest < ActionDispatch::IntegrationTest
  test "root shows today with its due goals" do
    travel_to Time.zone.local(2026, 8, 17, 9, 0) do
      Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
      Goal.create!(title: "One-off today", recurring: false, scheduled_on: Date.current)
      Goal.create!(title: "One-off tomorrow", recurring: false, scheduled_on: Date.current + 1)

      get root_path

      assert_response :success
      assert_select "body", text: /Daily habit/
      assert_select "body", text: /One-off today/
      assert_select "body", text: /One-off tomorrow/, count: 0
    end
  end

  test "shows weekly goals with a distinct badge" do
    monday = Date.new(2026, 8, 17)
    Goal.create!(title: "Weekly review", recurring: true, frequency: "weekly", active_from: monday - 7)

    get day_path(date: monday + 2)

    assert_response :success
    assert_select "body", text: /Weekly review/
    assert_select "body", text: /Cette semaine/
  end

  test "navigates to a specific date via the date param" do
    Goal.create!(title: "Old one-off", recurring: false, scheduled_on: Date.new(2026, 1, 1))

    get day_path(date: "2026-01-01")

    assert_response :success
    assert_select "body", text: /Old one-off/
  end
end
