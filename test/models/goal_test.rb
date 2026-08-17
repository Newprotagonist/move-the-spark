require "test_helper"

class GoalTest < ActiveSupport::TestCase
  test "one-off goal requires scheduled_on and defaults frequency to daily" do
    goal = Goal.new(title: "Buy milk", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    assert goal.valid?
    assert_equal "daily", goal.frequency
  end

  test "one-off goal is invalid without scheduled_on" do
    goal = Goal.new(title: "Buy milk", recurring: false)
    assert_not goal.valid?
    assert_includes goal.errors[:scheduled_on], "doit être rempli"
  end

  test "one-off goal cannot be weekly" do
    goal = Goal.new(title: "Buy milk", recurring: false, scheduled_on: Date.new(2026, 8, 17), frequency: "weekly")
    assert_not goal.valid?
    assert_includes goal.errors[:frequency], "must be daily for a one-off goal"
  end

  test "one-off goal cannot have active_from" do
    goal = Goal.new(title: "Buy milk", recurring: false, scheduled_on: Date.new(2026, 8, 17), active_from: Date.new(2026, 8, 1))
    assert_not goal.valid?
    assert_includes goal.errors[:active_from], "must be blank for a one-off goal"
  end

  test "recurring goal requires active_from and rejects scheduled_on" do
    goal = Goal.new(title: "Run", recurring: true, frequency: "daily", scheduled_on: Date.new(2026, 8, 17))
    assert_not goal.valid?
    assert_includes goal.errors[:scheduled_on], "must be blank for a recurring goal"

    goal.scheduled_on = nil
    assert_not goal.valid?
    assert_includes goal.errors[:active_from], "doit être rempli"

    goal.active_from = Date.new(2026, 8, 1)
    assert goal.valid?
  end

  test "recurring goal frequency must be daily or weekly" do
    goal = Goal.new(title: "Run", recurring: true, frequency: "hourly", active_from: Date.new(2026, 8, 1))
    assert_not goal.valid?
    assert_includes goal.errors[:frequency], "n'est pas une valeur autorisée"
  end

  test "due_on returns one-off goals scheduled that day and active recurring daily goals" do
    today = Date.new(2026, 8, 17)
    one_off_today = Goal.create!(title: "One-off today", recurring: false, scheduled_on: today)
    Goal.create!(title: "One-off other day", recurring: false, scheduled_on: today + 1)
    recurring_active = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: today - 5)
    Goal.create!(title: "Not yet active", recurring: true, frequency: "daily", active_from: today + 1)
    Goal.create!(title: "Weekly habit", recurring: true, frequency: "weekly", active_from: today - 5)

    assert_equal [ one_off_today, recurring_active ].sort_by(&:id), Goal.due_on(today).sort_by(&:id)
  end

  test "due_on excludes recurring daily goals archived before that date" do
    today = Date.new(2026, 8, 17)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: today - 5,
                         archived_at: today.beginning_of_day)
    assert_not_includes Goal.due_on(today), goal

    still_active = Goal.create!(title: "Daily habit 2", recurring: true, frequency: "daily", active_from: today - 5,
                                 archived_at: (today + 1).end_of_day)
    assert_includes Goal.due_on(today), still_active
  end

  test "due_in_week returns active recurring weekly goals for the week containing the date" do
    wednesday = Date.new(2026, 8, 19) # week of 2026-08-17 (Mon) .. 2026-08-23 (Sun)
    weekly = Goal.create!(title: "Weekly review", recurring: true, frequency: "weekly", active_from: wednesday - 30)
    Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: wednesday - 30)
    not_active_yet = Goal.create!(title: "Future weekly", recurring: true, frequency: "weekly", active_from: wednesday + 30)

    result = Goal.due_in_week(wednesday)
    assert_includes result, weekly
    assert_not_includes result, not_active_yet
  end

  test "average_duration_seconds matches by title across distinct goal rows" do
    g1 = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.new(2026, 8, 10))
    g2 = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.new(2026, 8, 11))
    GoalCompletion.create!(goal: g1, occurred_on: g1.scheduled_on, completed_at: Time.current, duration_seconds: 600)
    GoalCompletion.create!(goal: g2, occurred_on: g2.scheduled_on, completed_at: Time.current, duration_seconds: 1200)

    assert_equal 900.0, g1.average_duration_seconds
    assert_equal 900.0, g2.average_duration_seconds
  end

  test "average_duration_seconds ignores completions without a duration" do
    goal = Goal.create!(title: "Meditate", recurring: false, scheduled_on: Date.new(2026, 8, 10))
    GoalCompletion.create!(goal: goal, occurred_on: goal.scheduled_on, completed_at: Time.current, duration_seconds: nil)
    assert_nil goal.average_duration_seconds
  end
end
