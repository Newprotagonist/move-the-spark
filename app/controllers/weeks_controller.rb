class WeeksController < ApplicationController
  def show
    @week_start = (parse_date(params[:date]) || Date.current).beginning_of_week
    @week_end = @week_start.end_of_week
    @previous_week_start = @week_start - 7
    @next_week_start = @week_start + 7

    weekly_goals = current_user.goals.due_in_week(@week_start)
    @weekly_goals, pinned_weekly_goals = weekly_goals.partition { |goal| goal.scheduled_weekday.nil? }

    @days = (@week_start..@week_end).map do |date|
      pinned_today = pinned_weekly_goals.select { |goal| goal.due_on_weekday?(date) }
      { date: date, goals: current_user.goals.due_on(date) + pinned_today, appointments: current_user.appointments.on_date(date) }
    end

    pairs = @weekly_goals.map { |goal| [ goal.id, @week_start ] } +
      @days.flat_map { |day| day[:goals].map { |goal| [ goal.id, goal.occurrence_date(day[:date]) ] } }
    @completions = GoalCompletion.index_for(pairs)

    @weekly_streak = StreakCalculator.new(user: current_user, unit: :week, reference_date: @week_start).current_streak
    @week_progress = StreakCalculator.new(user: current_user, unit: :week, reference_date: @week_start).current_period_progress if current_week?
  end

  private

  def current_week?
    @week_start == Date.current.beginning_of_week
  end
end
