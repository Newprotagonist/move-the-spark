require "test_helper"

class GoalCompletionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @goal = Goal.create!(user: @user, title: "Run", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
  end

  test "valid with goal, occurred_on and completed_at" do
    completion = GoalCompletion.new(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    assert completion.valid?
  end

  test "only one completion per goal per occurred_on" do
    GoalCompletion.create!(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    dup = GoalCompletion.new(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    assert_not dup.valid?
    assert_includes dup.errors[:occurred_on], "est déjà utilisé"
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

  test "index_for bulk-loads and indexes completions by [goal_id, occurred_on], ignoring unrequested pairs" do
    other_goal = Goal.create!(user: @user, title: "Other", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    c1 = GoalCompletion.create!(goal: @goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)
    GoalCompletion.create!(goal: @goal, occurred_on: Date.new(2026, 8, 18), completed_at: Time.current)
    c3 = GoalCompletion.create!(goal: other_goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current)

    result = GoalCompletion.index_for([
      [ @goal.id, Date.new(2026, 8, 17) ],
      [ other_goal.id, Date.new(2026, 8, 17) ],
      [ @goal.id, Date.new(2026, 8, 19) ] # no completion exists for this pair
    ])

    assert_equal({
      [ @goal.id, Date.new(2026, 8, 17) ] => c1,
      [ other_goal.id, Date.new(2026, 8, 17) ] => c3
    }, result)
  end

  test "index_for returns an empty hash for no pairs" do
    assert_equal({}, GoalCompletion.index_for([]))
  end
end
