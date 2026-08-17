require "test_helper"

class GoalsControllerTest < ActionDispatch::IntegrationTest
  test "creates a one-off goal" do
    assert_difference("Goal.count", 1) do
      post goals_path, params: { goal: { title: "Buy milk", recurring: "false", scheduled_on: "2026-08-17" } }
    end
    assert_redirected_to root_path
    assert_equal "daily", Goal.last.frequency
  end

  test "creates a recurring weekly goal" do
    assert_difference("Goal.count", 1) do
      post goals_path, params: { goal: { title: "Review week", recurring: "true", frequency: "weekly", active_from: "2026-08-01" } }
    end
    assert_equal "weekly", Goal.last.frequency
  end

  test "invalid goal re-renders the form with errors" do
    assert_no_difference("Goal.count") do
      post goals_path, params: { goal: { title: "", recurring: "false" } }
    end
    assert_response :unprocessable_entity
  end

  test "updates a goal" do
    goal = Goal.create!(title: "Old title", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    patch goal_path(goal), params: { goal: { title: "New title" } }
    assert_redirected_to root_path
    assert_equal "New title", goal.reload.title
  end

  test "destroys a goal" do
    goal = Goal.create!(title: "Temp", recurring: false, scheduled_on: Date.new(2026, 8, 17))
    assert_difference("Goal.count", -1) do
      delete goal_path(goal)
    end
  end

  test "completing a goal creates a GoalCompletion for the given occurrence" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    assert_difference("GoalCompletion.count", 1) do
      post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    completion = goal.goal_completions.sole
    assert_equal Date.new(2026, 8, 17), completion.occurred_on
  end

  test "completing the same occurrence twice does not duplicate" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    assert_no_difference("GoalCompletion.count") do
      post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
  end

  test "uncompleting removes the GoalCompletion for that occurrence" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    assert_difference("GoalCompletion.count", -1) do
      post uncomplete_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
  end

  test "complete responds with a turbo stream replacing the goal row" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
  end
end
