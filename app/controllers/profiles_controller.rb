class ProfilesController < ApplicationController
  def show
    @heatmap = ActivityHeatmap.new(user: current_user)
    @focus_seconds_this_week = current_user.goal_completions
      .where(completed_at: Date.current.beginning_of_week.beginning_of_day..Date.current.end_of_week.end_of_day)
      .sum(:duration_seconds)
    @archived_goals_count = current_user.goals.archived.count
  end
end
