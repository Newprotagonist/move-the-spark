# Builds the day view's half-hourly timeline (07:00-22:30): each slot holds
# the appointments and scheduled-slot goals due that half hour, sorted by
# time within the slot. Goals only ever carry one scheduled_hour/minute
# total (not per occurrence/day — see Goal#scheduled_hour), so a recurring
# goal shows at the same slot on every day it's due.
class DayRibbon
  HOURS = (7..22).freeze
  MINUTES = [ 0, 30 ].freeze

  Slot = Struct.new(:hour, :minute, :appointments, :goals, keyword_init: true)

  def initialize(goals:, appointments:)
    @goals = goals
    @appointments = appointments
  end

  def slots
    HOURS.flat_map do |hour|
      MINUTES.map do |minute|
        Slot.new(
          hour: hour,
          minute: minute,
          appointments: @appointments.select { |a| a.starts_at.hour == hour && half_hour(a.starts_at.min) == minute }.sort_by(&:starts_at),
          goals: @goals.select { |g| g.scheduled_hour == hour && g.scheduled_minute == minute }.sort_by(&:title)
        )
      end
    end
  end

  private

  def half_hour(minute)
    minute < 30 ? 0 : 30
  end
end
