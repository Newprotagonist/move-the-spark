# Runs every 5 minutes (config/recurring.yml) but only actually sends once a
# day, at Setting#daily_goal_reminder_time or after, guarded by
# Setting#daily_goal_reminder_sent_on.
class DailyGoalReminderJob < ApplicationJob
  queue_as :default

  def perform
    # next, not return — these guards are per-user now (each user has their
    # own Setting/reminder time), so one user not being due yet must not
    # stop the whole batch from considering everyone after them.
    User.not_demo.find_each do |user|
      setting = user.setting
      next if setting.daily_goal_reminder_sent_on == Date.current
      next if Time.current.strftime("%H:%M") < setting.daily_goal_reminder_time.strftime("%H:%M")

      incomplete = incomplete_goals_today(user)
      if incomplete.any?
        PushSubscription.broadcast(
          user: user,
          title: "Objectifs du jour",
          body: "#{incomplete.size} objectif#{"s" if incomplete.size > 1} encore à faire aujourd'hui",
          path: Rails.application.routes.url_helpers.root_path
        )
      end

      setting.update!(daily_goal_reminder_sent_on: Date.current)
    end
  end

  private

  def incomplete_goals_today(user)
    today = Date.current
    due = user.goals.due_on(today)
    return due if due.empty?

    completed_ids = user.goal_completions.where(goal_id: due.map(&:id), occurred_on: today).pluck(:goal_id)
    due.reject { |goal| completed_ids.include?(goal.id) }
  end
end
