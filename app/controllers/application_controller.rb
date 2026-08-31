class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Single shared credential gating the whole app when hosted publicly — not
  # a real accounts system (see SPEC.md), just a defense-in-depth layer
  # against the URL being discovered (search crawlers, Certificate
  # Transparency logs, a leaked link) and against automated internet-wide
  # vulnerability scanners. Guarded behind ENV presence rather than
  # Rails.env.production? so it can also be exercised locally by setting the
  # same two vars. http_basic_authenticate_with requires String args, so this
  # can't unconditionally pass a possibly-nil ENV value — skipping the call
  # entirely when unset keeps local dev/test frictionless (unauthenticated,
  # as today). Kamal's own health check (/up) and the PWA manifest/service
  # worker routes are served by separate Rails-internal controllers that
  # don't inherit from this one, so they're unaffected either way.
  if ENV["BASIC_AUTH_USER"].present?
    http_basic_authenticate_with name: ENV["BASIC_AUTH_USER"], password: ENV.fetch("BASIC_AUTH_PASSWORD")
  end

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
