# Computes the current day or week streak: the number of consecutive
# day/week periods, walking backward from today/this-week, where every
# scheduled goal was completed.
#
# Rules (see PLAN.md):
# - A period with zero scheduled goals is neutral: it neither breaks nor
#   extends the streak, and the walk continues past it.
# - A period where every scheduled goal has a matching GoalCompletion
#   counts; the first period with any incomplete scheduled goal stops the
#   walk.
# - The current (in-progress) period is special-cased: if it isn't fully
#   complete yet, it must not zero out the streak — the walk simply starts
#   counting from the period before it. Live progress on the current period
#   is exposed separately via #current_period_progress.
class StreakCalculator
  MAX_LOOKBACK_UNITS = 365 * 3

  def initialize(user:, unit:, reference_date: Date.current)
    raise ArgumentError, "unit must be :day or :week" unless %i[day week].include?(unit)

    @user = user
    @unit = unit
    @reference_date = reference_date
  end

  def current_streak
    floor = earliest_possible_period
    return 0 if floor.nil?

    cursor = current_period
    cursor = previous(cursor) if in_progress?(cursor)

    count = 0
    units_checked = 0
    while units_checked < MAX_LOOKBACK_UNITS && cursor >= floor
      units_checked += 1
      scheduled = due_goals(cursor)

      if scheduled.empty?
        cursor = previous(cursor)
        next
      end

      break unless completed?(cursor, scheduled)

      count += 1
      cursor = previous(cursor)
    end

    count
  end

  def current_period_progress
    scheduled = due_goals(current_period)
    done = completed_goal_ids(current_period, scheduled).size
    { done: done, total: scheduled.size }
  end

  private

  # The earliest period any goal of this frequency could ever have been due.
  # Nothing scheduled before it, ever — so the backward walk can stop there
  # instead of trudging through years of guaranteed-empty periods. Returns
  # nil when no goal of this frequency has ever existed (streak is then 0).
  def earliest_possible_period
    if @unit == :week
      @user.goals.where(recurring: true, frequency: "weekly").minimum(:active_from)&.beginning_of_week
    else
      [
        @user.goals.where(recurring: true, frequency: "daily").minimum(:active_from),
        @user.goals.where(recurring: false).minimum(:scheduled_on)
      ].compact.min
    end
  end

  def current_period
    @unit == :week ? @reference_date.beginning_of_week : @reference_date
  end

  def previous(date)
    @unit == :week ? date - 7 : date - 1
  end

  def due_goals(date)
    @unit == :week ? @user.goals.due_in_week(date) : @user.goals.due_on(date)
  end

  def in_progress?(date)
    scheduled = due_goals(date)
    scheduled.any? && !completed?(date, scheduled)
  end

  def completed?(date, scheduled)
    return true if scheduled.empty?

    completed_goal_ids(date, scheduled).size == scheduled.size
  end

  def completed_goal_ids(date, scheduled)
    occurred_on = @unit == :week ? date.beginning_of_week : date
    @user.goal_completions.where(goal_id: scheduled.map(&:id), occurred_on: occurred_on).pluck(:goal_id)
  end
end
