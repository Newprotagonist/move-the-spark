require "test_helper"

class GoalCompletionTest < ActiveSupport::TestCase
  setup do
    @goal = Goal.create!(title: "Run", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
  end

  test "valid with goal, occurred_on and completed_at" do
    completion = GoalCompletion.new(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    assert completion.valid?
  end

  test "only one completion per goal per occurred_on" do
    GoalCompletion.create!(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    dup = GoalCompletion.new(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    assert_not dup.valid?
    assert_includes dup.errors[:occurred_on], "has already been taken"
  end

  test "database enforces the uniqueness constraint too" do
    GoalCompletion.create!(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    dup = GoalCompletion.new(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    assert_raises(ActiveRecord::RecordNotUnique) do
      dup.save(validate: false)
    end
  end

  test "same goal can have completions on different occurred_on dates" do
    GoalCompletion.create!(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    other = GoalCompletion.new(goal: @goal, occurred_on: Date.new(2026, 8, 18), completed_at: Time.current)
    assert other.valid?
  end
end
