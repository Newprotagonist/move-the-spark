class Appointment < ApplicationRecord
  validates :title, presence: true
  validates :starts_at, presence: true

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :on_date, ->(date) { where(starts_at: date.beginning_of_day..date.end_of_day).order(:starts_at) }
  scope :in_week, ->(date) { where(starts_at: date.beginning_of_week.beginning_of_day..date.end_of_week.end_of_day).order(:starts_at) }

  # The reminder lead time to use for this appointment: its own override if
  # set, otherwise the app-wide default from Setting.
  def effective_reminder_lead_minutes
    reminder_lead_minutes || Setting.instance.default_appointment_lead_minutes
  end

  def reminder_due_at
    starts_at - effective_reminder_lead_minutes.minutes
  end
end
