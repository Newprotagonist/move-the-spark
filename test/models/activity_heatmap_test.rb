require "test_helper"

class ActivityHeatmapTest < ActiveSupport::TestCase
  test "cells span the 35 days up to and including the reference date" do
    reference = Date.new(2026, 8, 17)
    heatmap = ActivityHeatmap.new(reference_date: reference)
    dates = heatmap.cells.map(&:date)

    assert_equal 35, dates.size
    assert_equal reference - 34, dates.first
    assert_equal reference, dates.last
  end

  test "level 0 when nothing is scheduled that day" do
    heatmap = ActivityHeatmap.new(reference_date: Date.new(2026, 8, 17))
    assert_equal 0, heatmap.cells.last.level
  end

  test "level 1 when goals are scheduled but none completed" do
    Goal.create!(title: "Sport", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    heatmap = ActivityHeatmap.new(reference_date: Date.new(2026, 8, 17))
    assert_equal 1, heatmap.cells.last.level
  end

  test "level 2 when some but not all goals are completed" do
    g1 = Goal.create!(title: "Sport", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    Goal.create!(title: "Lire", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    GoalCompletion.create!(goal: g1, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current, points_awarded: 10)

    heatmap = ActivityHeatmap.new(reference_date: Date.new(2026, 8, 17))
    assert_equal 2, heatmap.cells.last.level
  end

  test "level 3 when every scheduled goal is completed" do
    goal = Goal.create!(title: "Sport", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    GoalCompletion.create!(goal: goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current, points_awarded: 10)

    heatmap = ActivityHeatmap.new(reference_date: Date.new(2026, 8, 17))
    assert_equal 3, heatmap.cells.last.level
  end

  test "active_days_count counts only fully-completed days" do
    fully_done = Goal.create!(title: "Sport", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    GoalCompletion.create!(goal: fully_done, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current, points_awarded: 10)
    Goal.create!(title: "Lire", recurring: false, scheduled_on: Date.new(2026, 8, 16))

    heatmap = ActivityHeatmap.new(reference_date: Date.new(2026, 8, 17))
    assert_equal 1, heatmap.active_days_count
  end
end
