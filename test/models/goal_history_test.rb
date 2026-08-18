require "test_helper"

class GoalHistoryTest < ActiveSupport::TestCase
  test "recurring daily goal: one occurrence per day since active_from, done/not-done, with duration" do
    goal = Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.current - 2)
    GoalCompletion.create!(goal: goal, occurred_on: Date.current - 2, completed_at: Time.current, duration_seconds: 600, points_awarded: 10)
    GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, duration_seconds: 900, points_awarded: 10)

    occurrences = GoalHistory.new(goal).occurrences

    assert_equal [ Date.current - 2, Date.current - 1, Date.current ], occurrences.map(&:date)
    assert_equal [ true, false, true ], occurrences.map(&:done)
    assert_equal [ 600, nil, 900 ], occurrences.map(&:duration_seconds)
  end

  test "recurring weekly goal: one occurrence per week since active_from" do
    this_monday = Date.current.beginning_of_week
    goal = Goal.create!(title: "Bilan", recurring: true, frequency: "weekly", active_from: this_monday - 14)
    GoalCompletion.create!(goal: goal, occurred_on: this_monday - 14, completed_at: Time.current, points_awarded: 10)

    occurrences = GoalHistory.new(goal).occurrences

    assert_equal [ this_monday - 14, this_monday - 7, this_monday ], occurrences.map(&:date)
    assert_equal [ true, false, false ], occurrences.map(&:done)
  end

  test "recurring daily occurrences are capped to the last MAX_DAILY_OCCURRENCES" do
    goal = Goal.create!(title: "Old habit", recurring: true, frequency: "daily", active_from: Date.current - 100)

    occurrences = GoalHistory.new(goal).occurrences

    assert_equal GoalHistory::MAX_DAILY_OCCURRENCES, occurrences.size
    assert_equal Date.current, occurrences.last.date
  end

  test "one-off goals sharing a title are each their own occurrence, oldest to newest" do
    g1 = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.current - 5)
    g2 = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.current - 2)
    g3 = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.current)
    GoalCompletion.create!(goal: g1, occurred_on: g1.scheduled_on, completed_at: Time.current, duration_seconds: 300, points_awarded: 10)
    GoalCompletion.create!(goal: g3, occurred_on: g3.scheduled_on, completed_at: Time.current, duration_seconds: 500, points_awarded: 10)

    occurrences = GoalHistory.new(g2).occurrences

    assert_equal [ g1.scheduled_on, g2.scheduled_on, g3.scheduled_on ], occurrences.map(&:date)
    assert_equal [ true, false, true ], occurrences.map(&:done)
    assert_equal [ 300, nil, 500 ], occurrences.map(&:duration_seconds)
  end

  test "total_completions and average_duration_seconds match by title across goal rows" do
    g1 = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.current - 1)
    g2 = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.current)
    GoalCompletion.create!(goal: g1, occurred_on: g1.scheduled_on, completed_at: Time.current, duration_seconds: 600, points_awarded: 10)
    GoalCompletion.create!(goal: g2, occurred_on: g2.scheduled_on, completed_at: Time.current, duration_seconds: 1200, points_awarded: 10)

    history = GoalHistory.new(g1)

    assert_equal 2, history.total_completions
    assert_equal 900.0, history.average_duration_seconds
  end

  test "a recurring goal not yet active (active_from in the future) has no occurrences" do
    goal = Goal.create!(title: "Upcoming", recurring: true, frequency: "daily", active_from: Date.current + 5)
    assert_equal [], GoalHistory.new(goal).occurrences
  end
end
