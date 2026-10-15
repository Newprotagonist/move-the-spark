require "test_helper"

class WeeksControllerTest < ActionDispatch::IntegrationTest
  test "shows weekly goals and each day's daily goals for the week" do
    monday = Date.new(2026, 8, 17)
    weekly = Goal.create!(user: @current_user, title: "Weekly review", recurring: true, frequency: "weekly", active_from: monday - 7)
    daily = Goal.create!(user: @current_user, title: "Daily habit", recurring: true, frequency: "daily", active_from: monday - 7)
    one_off_wednesday = Goal.create!(user: @current_user, title: "Dentist prep", recurring: false, scheduled_on: monday + 2)

    get week_path(date: monday + 3)

    assert_response :success
    assert_select "body", text: /Weekly review/
    assert_select "body", text: /Daily habit/
    assert_select "body", text: /Dentist prep/
  end

  test "current_week route defaults to this week" do
    Goal.create!(user: @current_user, title: "Weekly review", recurring: true, frequency: "weekly", active_from: Date.current - 7)

    get current_week_path

    assert_response :success
    assert_select "body", text: /Weekly review/
  end

  test "any date within the week resolves to the same Monday-based week" do
    monday = Date.new(2026, 8, 17)
    Goal.create!(user: @current_user, title: "Weekly review", recurring: true, frequency: "weekly", active_from: monday - 7)

    get week_path(date: monday + 6) # the Sunday of that week

    assert_response :success
    assert_select "body", text: /Weekly review/
  end

  test "shows appointments within each day of the week" do
    monday = Date.new(2026, 8, 17)
    Appointment.create!(user: @current_user, title: "Dentiste", starts_at: Time.zone.local(2026, 8, 19, 14, 30))
    Appointment.create!(user: @current_user, title: "Next week rdv", starts_at: Time.zone.local(2026, 8, 24, 9, 0))

    get week_path(date: monday)

    assert_response :success
    assert_select "body", text: /Dentiste/
    assert_select "body", text: /Next week rdv/, count: 0
  end

  test "a pinned weekly goal appears once, in its day section rather than the generic weekly section" do
    monday = Date.new(2026, 8, 17)
    Goal.create!(user: @current_user, title: "Yoga", recurring: true, frequency: "weekly", active_from: monday - 7, scheduled_weekday: 2)

    get week_path(date: monday)

    assert_response :success
    assert_equal 1, response.body.scan("Yoga").length
    assert_select "body", text: /Aucun objectif hebdomadaire/
  end

  test "the complete button for a pinned weekly goal in its day section posts occurred_on as the week's Monday, not the pinned day" do
    monday = Date.new(2026, 8, 17)
    Goal.create!(user: @current_user, title: "Yoga", recurring: true, frequency: "weekly", active_from: monday - 7, scheduled_weekday: 2)

    get week_path(date: monday)

    assert_response :success
    assert_select "input[name=occurred_on][value=?]", monday.to_s
    assert_select "input[name=occurred_on][value=?]", (monday + 2).to_s, count: 0
  end

  test "completing a weekly goal from the week view works" do
    monday = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @current_user, title: "Weekly review", recurring: true, frequency: "weekly", active_from: monday - 7)

    assert_difference("GoalCompletion.count", 1) do
      post complete_goal_path(goal), params: { occurred_on: monday.to_s }
    end
    assert_equal monday, goal.goal_completions.sole.occurred_on
  end

  test "wires the swipe-nav controller to the previous and next week" do
    monday = Date.new(2026, 8, 17)

    get week_path(date: monday)

    assert_response :success
    assert_select "[data-controller='swipe-nav'][data-swipe-nav-previous-url-value=?]", week_path(date: monday - 7)
    assert_select "[data-controller='swipe-nav'][data-swipe-nav-next-url-value=?]", week_path(date: monday + 7)
  end
end
