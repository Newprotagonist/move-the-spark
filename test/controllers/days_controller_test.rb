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
    assert_select "body", text: /cette semaine/i
  end

  test "a weekly goal pinned to a weekday only appears on that day" do
    monday = Date.new(2026, 8, 17)
    Goal.create!(title: "Yoga", recurring: true, frequency: "weekly", active_from: monday - 7, scheduled_weekday: 2)

    get day_path(date: monday + 2) # Wednesday: the pinned day
    assert_response :success
    assert_select "body", text: /Yoga/

    get day_path(date: monday + 3) # Thursday: not the pinned day
    assert_response :success
    assert_select "body", text: /Yoga/, count: 0
  end

  test "a weekly goal pinned to a weekday shows its day abbreviation instead of the generic badge" do
    monday = Date.new(2026, 8, 17)
    Goal.create!(title: "Yoga", recurring: true, frequency: "weekly", active_from: monday - 7, scheduled_weekday: 2)

    get day_path(date: monday + 2) # Wednesday

    assert_response :success
    assert_select "body", text: /mer/i
    assert_select "body", text: /cette semaine/i, count: 0
  end

  test "navigates to a specific date via the date param" do
    Goal.create!(title: "Old one-off", recurring: false, scheduled_on: Date.new(2026, 1, 1))

    get day_path(date: "2026-01-01")

    assert_response :success
    assert_select "body", text: /Old one-off/
  end

  test "shows appointments for the day alongside goals in the same combined view" do
    Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    Appointment.create!(title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 14, 30))
    Appointment.create!(title: "Other day rdv", starts_at: Time.zone.local(2026, 8, 18, 9, 0))

    get day_path(date: "2026-08-17")

    assert_response :success
    assert_select "body", text: /Daily habit/
    assert_select "body", text: /Dentiste/
    assert_select "body", text: /Other day rdv/, count: 0
  end
end
