# Shared by DaysController#show (the full day page) and
# GoalsController#schedule (which needs to re-render just the day's ribbon
# after placing a goal into an hour slot) — both need the same goals/
# completions/appointments data for a given date.
module DayScoped
  extend ActiveSupport::Concern

  private

  def load_day(date)
    @date = date
    @daily_goals = current_user.goals.due_on(date)
    @weekly_goals = current_user.goals.due_in_week(date).select { |goal| goal.due_on_weekday?(date) }
    @completions = GoalCompletion.index_for(
      (@daily_goals + @weekly_goals).map { |goal| [ goal.id, goal.occurrence_date(date) ] }
    )
    @appointments = current_user.appointments.on_date(date)
  end
end
