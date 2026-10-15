# 5-week (35-day) daily-activity grid for the profile heatmap. Only reflects
# daily/one-off goals (Goal.due_on) — weekly goals are week-scoped, not
# day-scoped, so they have no single day to color a cell for.
class ActivityHeatmap
  DAYS = 35

  Cell = Struct.new(:date, :level, keyword_init: true)

  # level: 0 nothing scheduled that day, 1 scheduled but none done,
  # 2 partially done, 3 fully done (the day that would count toward streak).
  def initialize(user:, reference_date: Date.current)
    @user = user
    @reference_date = reference_date
  end

  def cells
    start_date = @reference_date - (DAYS - 1)
    (start_date..@reference_date).map { |date| Cell.new(date: date, level: level_for(date)) }
  end

  def active_days_count
    cells.count { |cell| cell.level == 3 }
  end

  private

  def level_for(date)
    goals = @user.goals.due_on(date)
    return 0 if goals.empty?

    completed = @user.goal_completions.where(goal_id: goals.map(&:id), occurred_on: date).count
    return 3 if completed == goals.size
    return 1 if completed.zero?

    2
  end
end
