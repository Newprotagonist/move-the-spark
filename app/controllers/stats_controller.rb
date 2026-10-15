class StatsController < ApplicationController
  def show
    @stats = GoalStats.new(user: current_user)
  end
end
