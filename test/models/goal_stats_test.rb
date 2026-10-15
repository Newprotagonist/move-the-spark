require "test_helper"

class GoalStatsTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "global_completion_rate is the pooled rate across all active recurring goals' occurrences" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      goal_a = Goal.create!(user: @user, title: "Sport", recurring: true, frequency: "daily", active_from: Date.current - 3)
      goal_b = Goal.create!(user: @user, title: "Lire", recurring: true, frequency: "daily", active_from: Date.current - 3)
      # goal_a: 4 occurrences (days -3..0), 2 done. goal_b: 4 occurrences, 4 done. Pooled: 6/8 = 75%.
      GoalCompletion.create!(goal: goal_a, occurred_on: Date.current - 3, completed_at: Time.current, points_awarded: 10)
      GoalCompletion.create!(goal: goal_a, occurred_on: Date.current - 2, completed_at: Time.current, points_awarded: 10)
      (0..3).each do |days_ago|
        GoalCompletion.create!(goal: goal_b, occurred_on: Date.current - days_ago, completed_at: Time.current, points_awarded: 10)
      end

      assert_equal 75, GoalStats.new(user: @user).global_completion_rate
    end
  end

  test "global_completion_rate is nil when there are no active recurring goals" do
    assert_nil GoalStats.new(user: @user).global_completion_rate
  end

  test "top_goals and bottom_goals exclude goals below the ranking threshold" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      established = Goal.create!(user: @user, title: "Established", recurring: true, frequency: "daily", active_from: Date.current - 4)
      3.times { |i| GoalCompletion.create!(goal: established, occurred_on: Date.current - i, completed_at: Time.current, points_awarded: 10) }

      fresh = Goal.create!(user: @user, title: "Fresh", recurring: true, frequency: "daily", active_from: Date.current)
      GoalCompletion.create!(goal: fresh, occurred_on: Date.current, completed_at: Time.current, points_awarded: 10)

      stats = GoalStats.new(user: @user)

      assert_equal [ "Established" ], stats.top_goals.map { |gr| gr.goal.title }
      assert_equal [], stats.bottom_goals.map { |gr| gr.goal.title }
    end
  end

  test "bottom_goals never includes a goal already surfaced in top_goals" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      7.times do |i|
        goal = Goal.create!(user: @user, title: "Goal #{i}", recurring: true, frequency: "daily", active_from: Date.current - 4, position: i)
        # Descending completion count per goal: 4, 3, 2, 1, 0, 0, 0 out of 5 occurrences.
        (0...(4 - i)).each do |days_ago|
          GoalCompletion.create!(goal: goal, occurred_on: Date.current - days_ago, completed_at: Time.current, points_awarded: 10)
        end
      end

      stats = GoalStats.new(user: @user)
      top_ids = stats.top_goals.map { |gr| gr.goal.id }
      bottom_ids = stats.bottom_goals.map { |gr| gr.goal.id }

      assert_empty top_ids & bottom_ids
      assert_equal [ "Goal 0", "Goal 1", "Goal 2", "Goal 3", "Goal 4" ], stats.top_goals.map { |gr| gr.goal.title }
      assert_equal [ "Goal 6", "Goal 5" ], stats.bottom_goals.map { |gr| gr.goal.title }
    end
  end

  test "ranking ties break by goal position" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      first = Goal.create!(user: @user, title: "First", recurring: true, frequency: "daily", active_from: Date.current - 2, position: 1)
      second = Goal.create!(user: @user, title: "Second", recurring: true, frequency: "daily", active_from: Date.current - 2, position: 2)
      # Both goals: 3 occurrences, 0 done -> identical 0% rate.

      stats = GoalStats.new(user: @user)

      assert_equal [ "First", "Second" ], stats.top_goals.map { |gr| gr.goal.title }
    end
  end

  test "best_weekday is driven by completed_at, not occurred_on" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      monday = Date.new(2026, 8, 17)
      goal = Goal.create!(user: @user, title: "Bilan", recurring: true, frequency: "weekly", active_from: monday - 7)
      # occurred_on is the week's Monday, but the actual click happened Tuesday.
      GoalCompletion.create!(goal: goal, occurred_on: monday, completed_at: Time.zone.local(2026, 8, 18, 10, 0), points_awarded: 10)

      weekday = GoalStats.new(user: @user).best_weekday

      assert_equal "mardi", I18n.l(weekday.date, format: "%A")
      assert_equal 1, weekday.count
    end
  end

  test "best_weekday is nil with no completions" do
    assert_nil GoalStats.new(user: @user).best_weekday
  end

  test "best_weekday counts one-off and archived-goal completions too" do
    tuesday = Time.zone.local(2026, 8, 18, 10, 0)
    one_off = Goal.create!(user: @user, title: "Buy milk", recurring: false, scheduled_on: tuesday.to_date)
    GoalCompletion.create!(goal: one_off, occurred_on: tuesday.to_date, completed_at: tuesday, points_awarded: 10)

    archived = Goal.create!(user: @user, title: "Old habit", recurring: true, frequency: "daily", active_from: tuesday.to_date - 7,
                             archived_at: tuesday + 1.day)
    GoalCompletion.create!(goal: archived, occurred_on: tuesday.to_date, completed_at: tuesday, points_awarded: 10)

    weekday = GoalStats.new(user: @user).best_weekday

    assert_equal 2, weekday.count
  end

  test "trend compares the last 14 days to the 14 days before that" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      improving = Goal.create!(user: @user, title: "Improving", recurring: true, frequency: "daily", active_from: Date.current - 27)
      # Previous period (days -27..-14): 1/14 done. Recent period (days -13..0): 13/14 done.
      GoalCompletion.create!(goal: improving, occurred_on: Date.current - 27, completed_at: Time.current, points_awarded: 10)
      (0..12).each do |days_ago|
        GoalCompletion.create!(goal: improving, occurred_on: Date.current - days_ago, completed_at: Time.current, points_awarded: 10)
      end

      trend = GoalStats.new(user: @user).trend

      assert_equal 93, trend[:recent].rate
      assert_equal 7, trend[:previous].rate
    end
  end

  test "trend's previous period rate is nil for a goal younger than 28 days" do
    travel_to Time.zone.local(2026, 8, 24, 9, 0) do
      goal = Goal.create!(user: @user, title: "New habit", recurring: true, frequency: "daily", active_from: Date.current - 5)
      GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, points_awarded: 10)

      trend = GoalStats.new(user: @user).trend

      assert_nil trend[:previous].rate
      assert_not_nil trend[:recent].rate
    end
  end
end
