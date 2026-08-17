# Runs every 5 minutes (config/recurring.yml) but only actually sends once a
# day, at Setting#daily_goal_reminder_time or after, guarded by
# Setting#daily_goal_reminder_sent_on.
class DailyGoalReminderJob < ApplicationJob
  queue_as :default

  def perform
    setting = Setting.instance
    return if setting.daily_goal_reminder_sent_on == Date.current
    return if Time.current.strftime("%H:%M") < setting.daily_goal_reminder_time.strftime("%H:%M")

    incomplete = incomplete_goals_today
    if incomplete.any?
      PushSubscription.broadcast(
        title: "Objectifs du jour",
        body: "#{incomplete.size} objectif#{"s" if incomplete.size > 1} encore à faire aujourd'hui",
        path: Rails.application.routes.url_helpers.root_path
      )
    end

    setting.update!(daily_goal_reminder_sent_on: Date.current)
  end

  private

  def incomplete_goals_today
    today = Date.current
    due = Goal.due_on(today)
    return due if due.empty?

    completed_ids = GoalCompletion.where(goal_id: due.map(&:id), occurred_on: today).pluck(:goal_id)
    due.reject { |goal| completed_ids.include?(goal.id) }
  end
end
