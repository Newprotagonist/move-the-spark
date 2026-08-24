class StatsController < ApplicationController
  def show
    @stats = GoalStats.new
  end
end
