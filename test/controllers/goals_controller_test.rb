require "test_helper"

class GoalsControllerTest < ActionDispatch::IntegrationTest
  test "creates a one-off goal and redirects to the day it's scheduled on" do
    assert_difference("Goal.count", 1) do
      post goals_path, params: { goal: { title: "Buy milk", recurring: "false", scheduled_on: "2026-08-17" } }
    end
    assert_redirected_to day_path(date: "2026-08-17")
    assert_equal "daily", Goal.last.frequency
  end

  test "creates a recurring weekly goal and redirects to today" do
    assert_difference("Goal.count", 1) do
      post goals_path, params: { goal: { title: "Review week", recurring: "true", frequency: "weekly", active_from: "2026-08-01" } }
    end
    assert_redirected_to root_path
    assert_equal "weekly", Goal.last.frequency
  end

  test "one-off goal creation ignores a stray active_from from the hidden recurring fields" do
    post goals_path, params: { goal: { title: "Buy milk", recurring: "false", scheduled_on: "2026-08-17", active_from: "2026-08-01", frequency: "weekly" } }
    goal = Goal.last
    assert goal.persisted?
    assert_nil goal.active_from
    assert_equal "daily", goal.frequency
  end

  test "recurring goal creation ignores a stray scheduled_on from the hidden one-off field" do
    post goals_path, params: { goal: { title: "Review week", recurring: "true", frequency: "weekly", active_from: "2026-08-01", scheduled_on: "2026-08-17" } }
    goal = Goal.last
    assert goal.persisted?
    assert_nil goal.scheduled_on
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

  test "completing a goal awards points_per_goal from Setting" do
    Setting.instance.update!(points_per_goal: 25)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    assert_equal 25, goal.goal_completions.sole.points_awarded
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

  test "start_timer records the current time and does not complete the goal" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    goal.reload
    assert goal.timer_running?
    assert_equal Time.zone.local(2026, 8, 17, 10, 0, 0), goal.current_timer_started_at
    assert_equal 0, goal.goal_completions.count
  end

  test "start_timer is a no-op if the timer is already running" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 5, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    assert_equal Time.zone.local(2026, 8, 17, 10, 0, 0), goal.reload.current_timer_started_at
  end

  test "stop_timer records the duration, completes the goal, and clears the running timer" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    Setting.instance.update!(points_per_goal: 15)

    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 25, 0) do
      post stop_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    goal.reload
    assert_not goal.timer_running?
    completion = goal.goal_completions.sole
    assert_equal 25 * 60, completion.duration_seconds
    assert_equal 15, completion.points_awarded
  end

  test "stop_timer without a running timer is a no-op" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    assert_no_difference("GoalCompletion.count") do
      post stop_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
  end

  test "focus starts the timer if it isn't already running" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      get focus_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    assert_response :success
    assert_equal Time.zone.local(2026, 8, 17, 10, 0, 0), goal.reload.current_timer_started_at
  end

  test "focus does not restart an already-running timer" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    travel_to Time.zone.local(2026, 8, 17, 10, 5, 0) do
      get focus_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    assert_equal Time.zone.local(2026, 8, 17, 10, 0, 0), goal.reload.current_timer_started_at
  end

  test "cancel_timer clears the running timer without completing the goal" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }

    assert_no_difference("GoalCompletion.count") do
      post cancel_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    assert_not goal.reload.timer_running?
  end

  test "cancel_timer redirects to return_to when given (focus page has no in-place target)" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }

    post cancel_timer_goal_path(goal), params: { occurred_on: "2026-08-17", return_to: day_path(date: "2026-08-17") }

    assert_redirected_to day_path(date: "2026-08-17")
  end

  test "complete responds with a turbo stream replacing the goal row" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
  end

  test "complete also replaces the day's progress ring for a daily goal" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_match "progress-ring", response.body
    assert_match "1/1", response.body
  end

  test "complete does not touch the progress ring for a weekly goal (occurred_on isn't the viewed day)" do
    goal = Goal.create!(title: "Weekly habit", recurring: true, frequency: "weekly", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_no_match "progress-ring", response.body
  end

  test "complete appends a points toast only the first time (not on a no-op repeat)" do
    Setting.instance.update!(points_per_goal: 20)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream
    assert_match "+20 points", response.body

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream
    assert_no_match "+20 points", response.body
  end

  test "uncomplete does not append a toast" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    post uncomplete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_no_match "toasts", response.body
  end

  test "stop_timer via html format sets a flash notice (the focus page's redirect path)" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }

    post stop_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }

    assert_match(/points/, flash[:notice])
  end

  test "stop_timer via turbo_stream format does not leak a flash into the session" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }

    post stop_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_nil flash[:notice]
    assert_match "toasts", response.body
  end

  test "schedule sets the goal's hour slot" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    patch schedule_goal_path(goal), params: { hour: 14, date: "2026-08-17" }

    assert_equal 14, goal.reload.scheduled_hour
  end

  test "schedule clears the hour slot when hour is blank" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1), scheduled_hour: 9)

    patch schedule_goal_path(goal), params: { hour: "", date: "2026-08-17" }

    assert_nil goal.reload.scheduled_hour
  end

  test "schedule responds with a turbo stream replacing the day ribbon" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    patch schedule_goal_path(goal), params: { hour: 14, date: "2026-08-17" }, as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
    assert_match "day-ribbon", response.body
  end

  test "schedule appends a toast naming the hour when setting a slot" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    patch schedule_goal_path(goal), params: { hour: 14, date: "2026-08-17" }, as: :turbo_stream

    assert_match "Casé à 14:00", response.body
  end

  test "schedule does not append a toast when clearing a slot" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1), scheduled_hour: 9)

    patch schedule_goal_path(goal), params: { hour: "", date: "2026-08-17" }, as: :turbo_stream

    assert_no_match "toasts", response.body
  end

  test "schedule redirects to the day when requested as html" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    patch schedule_goal_path(goal), params: { hour: 14, date: "2026-08-17" }

    assert_redirected_to day_path(date: "2026-08-17")
  end
end
