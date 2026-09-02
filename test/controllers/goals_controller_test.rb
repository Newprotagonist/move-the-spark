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
    Setting.instance.update!(points_per_goal: 25, streak_bonus_cap: 0)
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
    Setting.instance.update!(points_per_goal: 15, streak_bonus_cap: 0)

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

  test "pause_timer freezes the running timer" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    travel_to Time.zone.local(2026, 8, 17, 10, 5, 0) do
      post pause_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    goal.reload
    assert goal.timer_paused?
    assert_equal Time.zone.local(2026, 8, 17, 10, 5, 0), goal.timer_paused_at
  end

  test "pause_timer is a no-op when already paused or not running" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post pause_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    assert_not goal.reload.timer_paused?

    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 5, 0) do
      post pause_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 8, 0) do
      post pause_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    assert_equal Time.zone.local(2026, 8, 17, 10, 5, 0), goal.reload.timer_paused_at
  end

  test "resume_timer shifts current_timer_started_at forward by the paused span and clears the pause" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 5, 0) do
      post pause_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 20, 0) do
      post resume_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    goal.reload
    assert_not goal.timer_paused?
    # Started at 10:00, paused for 15 min (10:05 → 10:20), so the effective
    # start shifts to 10:15 — stopping 10 min after resuming (at 10:30)
    # should record only 15 min elapsed, not 30.
    assert_equal Time.zone.local(2026, 8, 17, 10, 15, 0), goal.current_timer_started_at

    travel_to Time.zone.local(2026, 8, 17, 10, 30, 0) do
      post stop_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    assert_equal 15 * 60, goal.goal_completions.sole.duration_seconds
  end

  test "stopping the timer while paused records the duration frozen at the pause, not wall-clock time to now" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    travel_to Time.zone.local(2026, 8, 17, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 10, 0) do
      post pause_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end
    travel_to Time.zone.local(2026, 8, 17, 10, 40, 0) do
      post stop_timer_goal_path(goal), params: { occurred_on: "2026-08-17" }
    end

    goal.reload
    assert_not goal.timer_paused?
    assert_equal 10 * 60, goal.goal_completions.sole.duration_seconds
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

  test "complete also replaces the ribbon, so a goal scheduled into an hour slot shows as done there too" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1), scheduled_hour: 9)

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_match "turbo-stream action=\"replace\" target=\"day-ribbon\"", response.body
  end

  test "uncomplete also replaces the ribbon for a daily goal" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1), scheduled_hour: 9)
    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    post uncomplete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_match "turbo-stream action=\"replace\" target=\"day-ribbon\"", response.body
  end

  test "complete does not touch the ribbon for a weekly goal (occurred_on isn't the viewed day)" do
    goal = Goal.create!(title: "Weekly habit", recurring: true, frequency: "weekly", active_from: Date.new(2026, 8, 1), scheduled_hour: 9)

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_no_match "day-ribbon", response.body
  end

  test "complete appends a points toast only the first time (not on a no-op repeat)" do
    Setting.instance.update!(points_per_goal: 20, streak_bonus_cap: 0)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream
    assert_match "+20 étincelles", response.body

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream
    assert_no_match "+20 étincelles", response.body
  end

  test "complete renders the completion burst only on the toggle that caused it, not on a no-op repeat" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream
    assert_match "flame-up", response.body

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream
    assert_no_match "flame-up", response.body
  end

  test "uncomplete does not render the completion burst" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    post uncomplete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_no_match "flame-up", response.body
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

    assert_match(/étincelles/, flash[:notice])
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

  test "schedule also replaces the checklist row so its HH:00 badge appears immediately" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    patch schedule_goal_path(goal), params: { hour: 9, date: "2026-08-17" }, as: :turbo_stream

    assert_match "turbo-stream action=\"replace\" target=\"2026-08-17_goal_#{goal.id}\"", response.body
    assert_match "09:00", response.body
  end

  test "schedule replaces the checklist row for a weekly goal at its week's occurrence, not the viewed day" do
    goal = Goal.create!(title: "Weekly habit", recurring: true, frequency: "weekly", active_from: Date.new(2026, 8, 1))
    wednesday = Date.new(2026, 8, 19) # week of 2026-08-17 (Mon)

    patch schedule_goal_path(goal), params: { hour: 9, date: wednesday.to_s }, as: :turbo_stream

    assert_match "turbo-stream action=\"replace\" target=\"2026-08-17_goal_#{goal.id}\"", response.body
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

  test "the schedule route also serves as the unschedule ('retirer du ruban') action" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1), scheduled_hour: 9)

    patch schedule_goal_path(goal), params: { hour: "", date: "2026-08-17" }, as: :turbo_stream

    assert_nil goal.reload.scheduled_hour
    assert_no_match "09:00", response.body
  end

  test "archive stops a recurring goal from being due, keeping its completion history" do
    goal = Goal.create!(title: "Habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    GoalCompletion.create!(goal: goal, occurred_on: Date.new(2026, 8, 5), completed_at: Time.current, points_awarded: 10)

    post archive_goal_path(goal)

    goal.reload
    assert goal.archived?
    assert_not_includes Goal.due_on(Date.current + 1), goal
    assert_equal 1, goal.goal_completions.count
  end

  test "unarchive makes a goal due again" do
    goal = Goal.create!(title: "Habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1),
                         archived_at: (Date.current - 5).beginning_of_day)

    post unarchive_goal_path(goal)

    goal.reload
    assert_not goal.archived?
    assert_includes Goal.due_on(Date.current), goal
  end

  test "archived index lists only archived goals" do
    archived = Goal.create!(title: "Old habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1),
                             archived_at: Date.new(2026, 8, 10).beginning_of_day)
    Goal.create!(title: "Current habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    get archived_goals_path

    assert_response :success
    assert_select "body", text: /Old habit/
    assert_select "body", text: /Current habit/, count: 0
  end

  test "toggling a goal from a plannable: false context (week view) keeps plannable false on re-render" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    post complete_goal_path(goal), params: { occurred_on: "2026-08-17", plannable: "false" }, as: :turbo_stream

    assert_no_match "Caser dans le ruban", response.body
  end

  test "toggling a goal without a plannable param defaults to plannable true (day view)" do
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }

    # No plannable param at all — should default true, same as a fresh day-view render.
    post uncomplete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream

    assert_match "Caser dans le ruban", response.body
  end

  test "completing a goal that grows the daily streak awards a bonus on top of points_per_goal" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 10)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))

    # This is also the day's only (and therefore last) daily goal, so the
    # celebration overlay fires instead of a toast (see the dedicated
    # celebration tests below) — this test only cares about the bonus math
    # ending up on the completion row, not which UI element renders it.
    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post complete_goal_path(goal), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
    end

    completion = goal.goal_completions.sole
    assert_equal 11, completion.points_awarded
  end

  test "completing a goal does not award a bonus when the streak does not grow" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 10)
    goal_a = Goal.create!(title: "Habit A", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))
    Goal.create!(title: "Habit B", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))

    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post complete_goal_path(goal_a), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
    end

    completion = goal_a.goal_completions.sole
    assert_equal 10, completion.points_awarded
    assert_no_match "flamme", response.body
  end

  test "streak bonus is capped at streak_bonus_cap" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 2)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 17))
    GoalCompletion.create!(goal: goal, occurred_on: Date.new(2026, 8, 17), completed_at: Time.current, points_awarded: 10)
    GoalCompletion.create!(goal: goal, occurred_on: Date.new(2026, 8, 18), completed_at: Time.current, points_awarded: 10)
    GoalCompletion.create!(goal: goal, occurred_on: Date.new(2026, 8, 19), completed_at: Time.current, points_awarded: 10)

    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post complete_goal_path(goal), params: { occurred_on: "2026-08-20" }
    end

    # The real streak just grew to 4, but the bonus caps at 2.
    assert_equal 12, goal.goal_completions.find_by(occurred_on: "2026-08-20").points_awarded
  end

  test "stop_timer also awards the streak bonus when it grows the streak" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 10)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))

    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post start_timer_goal_path(goal), params: { occurred_on: "2026-08-20" }
    end
    travel_to Time.zone.local(2026, 8, 20, 10, 5, 0) do
      post stop_timer_goal_path(goal), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
    end

    completion = goal.goal_completions.sole
    assert_equal 11, completion.points_awarded
  end

  test "completing the last remaining daily goal of the day shows the celebration overlay instead of a toast" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 10)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))

    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post complete_goal_path(goal), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
    end

    assert_match "celebration-overlay", response.body
    assert_no_match "rise-fade", response.body # no toast alongside it
  end

  test "completing a goal that still leaves another daily goal undone does not show the celebration overlay" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 10)
    goal_a = Goal.create!(title: "Habit A", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))
    Goal.create!(title: "Habit B", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))

    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post complete_goal_path(goal_a), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
    end

    assert_no_match "celebration-overlay", response.body
    assert_match "rise-fade", response.body
  end

  test "the celebration overlay does not fire twice in the same day after unchecking and rechecking the last goal" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 10)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 20))

    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post complete_goal_path(goal), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
      assert_match "celebration-overlay", response.body

      post uncomplete_goal_path(goal), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
      post complete_goal_path(goal), params: { occurred_on: "2026-08-20" }, as: :turbo_stream
      assert_no_match "celebration-overlay", response.body
      assert_match "rise-fade", response.body
    end
  end

  test "the celebration overlay does not fire for a retroactive completion of a past day" do
    Setting.instance.update!(points_per_goal: 10, streak_bonus_cap: 10)
    goal = Goal.create!(title: "Daily habit", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    travel_to Time.zone.local(2026, 8, 20, 10, 0, 0) do
      post complete_goal_path(goal), params: { occurred_on: "2026-08-17" }, as: :turbo_stream
    end

    assert_no_match "celebration-overlay", response.body
    assert_match "rise-fade", response.body
  end

  test "history renders stats and the completion strip for a goal" do
    goal = Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 15))
    GoalCompletion.create!(goal: goal, occurred_on: Date.new(2026, 8, 15), completed_at: Time.current, duration_seconds: 600, points_awarded: 10)

    get history_goal_path(goal)

    assert_response :success
    assert_match "complétion", response.body
    assert_match "min en moyenne", response.body
  end
end
