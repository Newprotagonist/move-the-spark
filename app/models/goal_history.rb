# A goal's occurrence pattern over time — "did I do this" per due period,
# plus the timed duration when there was one. Matches by title (not
# goal_id), same convention as Goal#average_duration_seconds: an ad-hoc
# one-off goal retyped on different days shares history with a "true"
# recurring goal of the same title.
class GoalHistory
  MAX_DAILY_OCCURRENCES = 35   # matches ActivityHeatmap's own window
  MAX_WEEKLY_OCCURRENCES = 12  # ~3 months

  Occurrence = Struct.new(:date, :done, :duration_seconds, keyword_init: true)

  def initialize(goal)
    @goal = goal
  end

  # Oldest to newest.
  def occurrences
    @goal.recurring? ? recurring_occurrences : one_off_occurrences
  end

  def total_completions
    completions.count
  end

  def average_duration_seconds
    @goal.average_duration_seconds
  end

  private

  def completions
    GoalCompletion.joins(:goal).where(goals: { title: @goal.title })
  end

  def recurring_occurrences
    @goal.weekly? ? recurring_weekly_occurrences : recurring_daily_occurrences
  end

  def recurring_daily_occurrences
    days = (@goal.active_from..Date.current).to_a.last(MAX_DAILY_OCCURRENCES)
    by_date = completions.where(occurred_on: days).index_by(&:occurred_on)
    days.map { |date| occurrence_for(date, by_date[date]) }
  end

  def recurring_weekly_occurrences
    weeks = weeks_since_active_from.last(MAX_WEEKLY_OCCURRENCES)
    by_week = completions.where(occurred_on: weeks).index_by(&:occurred_on)
    weeks.map { |week_start| occurrence_for(week_start, by_week[week_start]) }
  end

  def weeks_since_active_from
    weeks = []
    cursor = @goal.active_from.beginning_of_week
    last = Date.current.beginning_of_week
    while cursor <= last
      weeks << cursor
      cursor += 7
    end
    weeks
  end

  # Every one-off goal ever created with this title is itself one
  # occurrence, whether or not it was ever completed.
  def one_off_occurrences
    goals = Goal.where(title: @goal.title, recurring: false).order(scheduled_on: :desc).limit(MAX_DAILY_OCCURRENCES)
    completion_by_goal_id = GoalCompletion.where(goal_id: goals.map(&:id)).index_by(&:goal_id)
    goals.reverse.map { |g| occurrence_for(g.scheduled_on, completion_by_goal_id[g.id]) }
  end

  def occurrence_for(date, completion)
    Occurrence.new(date: date, done: completion.present?, duration_seconds: completion&.duration_seconds)
  end
end
