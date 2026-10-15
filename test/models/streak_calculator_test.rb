require "test_helper"

class StreakCalculatorTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  def complete!(goal, occurred_on)
    GoalCompletion.create!(goal: goal, occurred_on: occurred_on, completed_at: occurred_on.to_time, points_awarded: 10)
  end

  # --- Daily streak -------------------------------------------------------

  test "all-complete: counts every consecutive fully-completed day" do
    today = Date.new(2026, 8, 17) # Monday
    goal = Goal.create!(user: @user, title: "Habit", recurring: true, frequency: "daily", active_from: today - 10)
    (0..4).each { |n| complete!(goal, today - n) } # today .. today-4, all done

    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    assert_equal 5, streak
  end

  test "one-incomplete: stops the walk at the first incomplete day in the past" do
    today = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @user, title: "Habit", recurring: true, frequency: "daily", active_from: today - 10)
    complete!(goal, today)
    complete!(goal, today - 1)
    # today - 2 missing
    complete!(goal, today - 3)

    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    assert_equal 2, streak
  end

  test "zero-scheduled: a day with no due goals is skipped, not counted, not breaking" do
    today = Date.new(2026, 8, 17)
    # Two one-off goals with a gap on today-1, which then has zero scheduled goals.
    one_off_today = Goal.create!(user: @user, title: "Today", recurring: false, scheduled_on: today)
    one_off_two_days_ago = Goal.create!(user: @user, title: "Two days ago", recurring: false, scheduled_on: today - 2)
    complete!(one_off_today, today)
    complete!(one_off_two_days_ago, today - 2)
    # today - 1 has zero one-off goals scheduled: neutral, should be skipped

    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    assert_equal 2, streak
  end

  test "in-progress-today: an unfinished today does not break the streak, and is not counted yet" do
    today = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @user, title: "Habit", recurring: true, frequency: "daily", active_from: today - 5)
    complete!(goal, today - 1)
    complete!(goal, today - 2)
    complete!(goal, today - 3)
    # today itself: not completed yet

    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    assert_equal 3, streak
  end

  test "today fully completed joins the streak" do
    today = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @user, title: "Habit", recurring: true, frequency: "daily", active_from: today - 5)
    complete!(goal, today)
    complete!(goal, today - 1)

    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    assert_equal 2, streak
  end

  test "goal-archived-mid-streak: archiving stops requiring completion from the archive date on" do
    today = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @user, title: "Habit", recurring: true, frequency: "daily", active_from: today - 5)
    complete!(goal, today - 4)
    complete!(goal, today - 3)
    # Archive the goal after today-3: from today-2 onward it's no longer scheduled.
    goal.update!(archived_at: (today - 2).beginning_of_day)

    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    # today, today-1, today-2 all have zero scheduled goals (archived) -> neutral/skipped
    # today-3 and today-4 are both complete -> streak of 2
    assert_equal 2, streak
  end

  test "goal-started-mid-streak: days before active_from have zero scheduled goals" do
    today = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @user, title: "Habit", recurring: true, frequency: "daily", active_from: today - 2)
    complete!(goal, today)
    complete!(goal, today - 1)
    complete!(goal, today - 2)
    # today-3 predates active_from -> zero scheduled -> neutral, walk continues indefinitely
    # since there's nothing before, MAX_LOOKBACK_UNITS bounds the loop; streak should be 3.

    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    assert_equal 3, streak
  end

  test "no goals ever: streak is zero and does not hang" do
    today = Date.new(2026, 8, 17)
    streak = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_streak
    assert_equal 0, streak
  end

  test "current_period_progress reports done/total for today without affecting the streak" do
    today = Date.new(2026, 8, 17)
    g1 = Goal.create!(user: @user, title: "A", recurring: true, frequency: "daily", active_from: today - 5)
    g2 = Goal.create!(user: @user, title: "B", recurring: true, frequency: "daily", active_from: today - 5)
    complete!(g1, today)

    progress = StreakCalculator.new(user: @user, unit: :day, reference_date: today).current_period_progress
    assert_equal({ done: 1, total: 2 }, progress)
  end

  # --- Weekly streak --------------------------------------------------------

  test "weekly streak counts consecutive fully-completed weeks" do
    this_monday = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @user, title: "Weekly review", recurring: true, frequency: "weekly", active_from: this_monday - 21)
    complete!(goal, this_monday)
    complete!(goal, this_monday - 7)
    complete!(goal, this_monday - 14)

    streak = StreakCalculator.new(user: @user, unit: :week, reference_date: this_monday + 3).current_streak
    assert_equal 3, streak
  end

  test "weekly streak: in-progress current week does not break it" do
    this_monday = Date.new(2026, 8, 17)
    goal = Goal.create!(user: @user, title: "Weekly review", recurring: true, frequency: "weekly", active_from: this_monday - 21)
    complete!(goal, this_monday - 7)
    complete!(goal, this_monday - 14)
    # current week not completed yet

    streak = StreakCalculator.new(user: @user, unit: :week, reference_date: this_monday + 2).current_streak
    assert_equal 2, streak
  end
end
