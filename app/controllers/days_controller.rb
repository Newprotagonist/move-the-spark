class DaysController < ApplicationController
  def show
    @date = parse_date(params[:date]) || Date.current
    @previous_date = @date - 1
    @next_date = @date + 1

    @daily_goals = Goal.due_on(@date)
    @weekly_goals = Goal.due_in_week(@date)
    @completions = completions_for(@daily_goals + @weekly_goals)

    @today_progress = StreakCalculator.new(unit: :day, reference_date: @date).current_period_progress if @date == Date.current
  end

  private

  def completions_for(goals)
    GoalCompletion.index_for(goals.map { |goal| [ goal.id, goal.occurrence_date(@date) ] })
  end
end
