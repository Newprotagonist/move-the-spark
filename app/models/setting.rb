# One row per user — created eagerly in User#after_create (see user.rb), so
# `user.setting` is always present; there's no lazy first_or_create! here
# the way there was back when this was a single global row.
class Setting < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :points_per_goal, numericality: { greater_than: 0 }
  validates :default_appointment_lead_minutes, numericality: { greater_than: 0 }
  validates :daily_goal_reminder_time, presence: true
  validates :streak_bonus_cap, numericality: { greater_than_or_equal_to: 0 }
end
