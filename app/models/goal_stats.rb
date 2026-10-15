# Aggregate stats over active recurring goals (daily + weekly), built on top
# of GoalHistory's per-goal occurrence data — no new occurrence-computation
# logic here, just wrapping/aggregating GoalHistory instances.
#
# One-off goals are excluded from every stat except #best_weekday: they're
# inherently binary per-row (0%/100%), not meaningful to rank or average as
# "habits." #best_weekday intentionally looks at ALL GoalCompletion rows
# (recurring + one-off, including completions of now-archived goals) since
# it's a lifetime "when do you tend to get things done" stat, not scoped to
# what's currently active.
class GoalStats
  MIN_OCCURRENCES_FOR_RANKING = 3
  RANKING_SIZE = 5
  RECENT_WINDOW_DAYS = 14

  GoalRate = Struct.new(:goal, :done, :total, keyword_init: true) do
    def rate
      total.zero? ? 0 : (done.to_f / total * 100).round
    end
  end

  TrendPeriod = Struct.new(:done, :total, keyword_init: true) do
    def rate
      total.zero? ? nil : (done.to_f / total * 100).round
    end
  end

  WeekdayStat = Struct.new(:date, :count, :total, keyword_init: true) do
    def percent
      total.zero? ? 0 : (count.to_f / total * 100).round
    end
  end

  def initialize(user:)
    @user = user
    @goals = active_recurring_goals
    # GoalHistory#occurrences is not memoized internally and re-queries on
    # every call — fetch each goal's occurrences exactly once here and reuse
    # the resulting arrays everywhere below, instead of re-instantiating or
    # re-calling per stat.
    @occurrences_by_goal_id = @goals.index_by(&:id).transform_values { |goal| GoalHistory.new(goal).occurrences }
  end

  def global_completion_rate
    occurrences = @occurrences_by_goal_id.values.flatten
    return nil if occurrences.empty?

    (occurrences.count(&:done).to_f / occurrences.size * 100).round
  end

  def top_goals
    ranked_goals.first(RANKING_SIZE)
  end

  # Excludes anything already surfaced in #top_goals so a goal is never
  # shown as both "most" and "least" realized at once — with few active
  # goals this can leave bottom_goals shorter than RANKING_SIZE, or empty.
  def bottom_goals
    top_ids = top_goals.map { |goal_rate| goal_rate.goal.id }
    ranked_goals.reverse.reject { |goal_rate| top_ids.include?(goal_rate.goal.id) }.first(RANKING_SIZE)
  end

  # completed_at (not occurred_on) drives this: occurred_on for a weekly
  # goal is always its week's Monday regardless of which day it was
  # actually checked off, so grouping by occurred_on's weekday would always
  # bucket weekly completions into "Monday". completed_at is the real,
  # always-present completion timestamp.
  def best_weekday
    total = 0
    counts = Hash.new(0)
    @user.goal_completions.pluck(:completed_at).each do |time|
      counts[(time.wday - 1) % 7] += 1 # Date#wday is 0=Sunday; this app's week is 0=Monday
      total += 1
    end
    return nil if counts.empty?

    weekday, count = counts.max_by { |wd, c| [ c, -wd ] } # ties break toward Monday, deterministic
    WeekdayStat.new(date: Date.current.beginning_of_week + weekday, count: count, total: total)
  end

  def trend
    today = Date.current
    recent_cutoff = today - RECENT_WINDOW_DAYS
    previous_cutoff = today - (2 * RECENT_WINDOW_DAYS)
    recent = TrendPeriod.new(done: 0, total: 0)
    previous = TrendPeriod.new(done: 0, total: 0)

    @occurrences_by_goal_id.each_value do |occurrences|
      occurrences.each do |occurrence|
        if occurrence.date > recent_cutoff
          recent.total += 1
          recent.done += 1 if occurrence.done
        elsif occurrence.date > previous_cutoff
          previous.total += 1
          previous.done += 1 if occurrence.done
        end
      end
    end

    { recent: recent, previous: previous }
  end

  private

  def active_recurring_goals
    @user.goals.recurring_daily.not_archived_as_of(Date.current).where("active_from <= ?", Date.current).ordered.to_a +
      @user.goals.due_in_week(Date.current).to_a
  end

  def ranked_goals
    @ranked_goals ||= @goals.filter_map { |goal|
      occurrences = @occurrences_by_goal_id[goal.id]
      next if occurrences.size < MIN_OCCURRENCES_FOR_RANKING

      GoalRate.new(goal: goal, done: occurrences.count(&:done), total: occurrences.size)
    }.sort_by { |gr| [ -gr.rate, gr.goal.position ] } # tie-break via Goal#position, this app's own ordering field
  end
end
