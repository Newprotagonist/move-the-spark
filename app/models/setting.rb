# Single-row settings table for this single-user app. Always use
# `Setting.instance` rather than `Setting.new`/`.find` — it lazily creates
# the one row (with column defaults) on first access.
class Setting < ApplicationRecord
  validates :points_per_goal, numericality: { greater_than: 0 }
  validates :default_appointment_lead_minutes, numericality: { greater_than: 0 }
  validates :daily_goal_reminder_time, presence: true

  def self.instance
    first_or_create!
  end
end
