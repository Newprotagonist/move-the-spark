class ProfilesController < ApplicationController
  def show
    @heatmap = ActivityHeatmap.new
    @focus_seconds_this_week = GoalCompletion
      .where(completed_at: Date.current.beginning_of_week.beginning_of_day..Date.current.end_of_week.end_of_day)
      .sum(:duration_seconds)
  end
end
