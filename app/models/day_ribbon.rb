# Builds the day view's hourly timeline (07:00-22:00): each hour holds the
# appointments and scheduled-hour goals due that hour, sorted by time within
# the hour. Goals only ever carry one scheduled_hour total (not per
# occurrence/day — see Goal#scheduled_hour), so a recurring goal shows at
# the same hour on every day it's due.
class DayRibbon
  HOURS = (7..22).freeze

  Hour = Struct.new(:hour, :appointments, :goals, keyword_init: true)

  def initialize(goals:, appointments:)
    @goals = goals
    @appointments = appointments
  end

  def hours
    HOURS.map do |hour|
      Hour.new(
        hour: hour,
        appointments: @appointments.select { |a| a.starts_at.hour == hour }.sort_by(&:starts_at),
        goals: @goals.select { |g| g.scheduled_hour == hour }.sort_by(&:title)
      )
    end
  end
end
