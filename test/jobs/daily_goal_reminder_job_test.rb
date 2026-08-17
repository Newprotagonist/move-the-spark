require "test_helper"

class DailyGoalReminderJobTest < ActiveJob::TestCase
  test "sends once past the reminder time when goals are still incomplete" do
    Setting.instance.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 18, 5) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 1, calls.size
    assert_equal Date.new(2026, 8, 17), Setting.instance.daily_goal_reminder_sent_on
  end

  test "does not send before the configured reminder time" do
    Setting.instance.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 17, 0) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
    assert_nil Setting.instance.daily_goal_reminder_sent_on
  end

  test "does not send when all of today's goals are already complete" do
    Setting.instance.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    goal = Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

    calls = []
    travel_to Time.zone.local(2026, 8, 17, 18, 5) do
      GoalCompletion.create!(goal: goal, occurred_on: Date.current, completed_at: Time.current, points_awarded: 10)
      Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
    assert_equal Date.new(2026, 8, 17), Setting.instance.daily_goal_reminder_sent_on
  end

  test "never sends twice in the same day" do
    Setting.instance.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Goal.create!(title: "Sport", recurring: true, frequency: "daily", active_from: Date.new(2026, 8, 1))

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
    Setting.instance.update!(daily_goal_reminder_time: "18:00")
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 18, 5) do
        DailyGoalReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
    assert_equal Date.new(2026, 8, 17), Setting.instance.daily_goal_reminder_sent_on
  end
end
