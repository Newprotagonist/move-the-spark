require "test_helper"

class DailyGoalReminderJobTest < ActiveJob::TestCase
  setup { @user = users(:one) }

  test "sends once past the reminder time when goals are still incomplete" do
    @user.setting.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Goal.create!(user: @user, title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 18, 5) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 1, calls.size
    assert_equal Date.new(2026, 8, 17), @user.setting.reload.daily_goal_reminder_sent_on
  end

  test "does not send before the configured reminder time" do
    @user.setting.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Goal.create!(user: @user, title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 17, 0) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
    assert_nil @user.setting.reload.daily_goal_reminder_sent_on
  end

  test "does not send when all of today's goals are already complete" do
    @user.setting.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    goal = Goal.create!(user: @user, title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    travel_to Time.zone.local(2026, 8, 17, 18, 5) do
      GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, points_awarded: 10)
      Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
    assert_equal Date.new(2026, 8, 17), @user.setting.reload.daily_goal_reminder_sent_on
  end

  test "never sends twice in the same day" do
    @user.setting.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Goal.create!(user: @user, title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 18, 5) do
        DailyGoalReminderJob.perform_now
      end
      travel_to Time.zone.local(2026, 8, 17, 19, 0) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 1, calls.size
  end

  test "does nothing when no goals are due today" do
    @user.setting.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 18, 5) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
    assert_equal Date.new(2026, 8, 17), @user.setting.reload.daily_goal_reminder_sent_on
  end

  # Regression guard: the per-user guards inside the User.find_each loop
  # must `next`, not `return` — a `return` would abort the whole batch the
  # moment the FIRST user in find_each order isn't due yet, silently
  # starving every user after them. users(:one) sorts before users(:two)
  # by id, so one not being due yet is exactly the scenario that would
  # have masked two's reminder under the old single-Setting `return` logic.
  test "one user not being due yet does not block another user who is" do
    not_due_yet = @user
    due_now = users(:two)
    not_due_yet.setting.update!(daily_goal_reminder_time: "20:00")
    due_now.setting.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(user: not_due_yet, endpoint: "https://push.example/not-due", p256dh_key: "a", auth_key: "b")
    PushSubscription.create!(user: due_now, endpoint: "https://push.example/due", p256dh_key: "c", auth_key: "d")
    Goal.create!(user: not_due_yet, title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))
    Goal.create!(user: due_now, title: "Lire", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 18, 5) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal [ "https://push.example/due" ], calls.map { |c| c[:endpoint] }
    assert_nil not_due_yet.setting.reload.daily_goal_reminder_sent_on
    assert_equal Date.new(2026, 8, 17), due_now.setting.reload.daily_goal_reminder_sent_on
  end
end
