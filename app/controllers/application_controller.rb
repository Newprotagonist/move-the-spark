class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :load_gamification_summary

  def current_user = Current.user
  helper_method :current_user

  private

  # Total points and current streak are shown in the layout header on every
  # page, not just the day view, so they're loaded here rather than per-action.
  # A no-op on the handful of actions that allow_unauthenticated_access
  # (login, password reset) — there's no one to load this for yet there.
  def load_gamification_summary
    return unless current_user

    @total_points = current_user.goal_completions.sum(:points_awarded)
    @daily_streak = StreakCalculator.new(user: current_user, unit: :day).current_streak
  end

  def parse_date(value)
    Date.parse(value) if value.present?
  rescue ArgumentError
    nil
  end
end
