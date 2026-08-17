class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :load_gamification_summary

  private

  # Total points and current streak are shown in the layout header on every
  # page, not just the day view, so they're loaded here rather than per-action.
  def load_gamification_summary
    @total_points = GoalCompletion.sum(:points_awarded)
    @daily_streak = StreakCalculator.new(unit: :day).current_streak
  end

  def parse_date(value)
    Date.parse(value) if value.present?
  rescue ArgumentError
    nil
  end
end
