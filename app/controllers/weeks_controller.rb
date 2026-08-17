class WeeksController < ApplicationController
  def show
    @week_start = (parse_date(params[:date]) || Date.current).beginning_of_week
    @week_end = @week_start.end_of_week
    @previous_week_start = @week_start - 7
    @next_week_start = @week_start + 7

    @weekly_goals = Goal.due_in_week(@week_start)
    @days = (@week_start..@week_end).map { |date| { date: date, goals: Goal.due_on(date), appointments: Appointment.on_date(date) } }

    pairs = @weekly_goals.map { |goal| [ goal.id, @week_start ] } +
      @days.flat_map { |day| day[:goals].map { |goal| [ goal.id, day[:date] ] } }
    @completions = GoalCompletion.index_for(pairs)

    @weekly_streak = StreakCalculator.new(unit: :week, reference_date: @week_start).current_streak
    @week_progress = StreakCalculator.new(unit: :week, reference_date: @week_start).current_period_progress if current_week?
  end

  private

  def current_week?
    @week_start == Date.current.beginning_of_week
  end
end
