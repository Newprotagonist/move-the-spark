require "test_helper"

class DayRibbonTest < ActiveSupport::TestCase
  test "hours span 07:00 to 22:00" do
    ribbon = DayRibbon.new(goals: [], appointments: [])
    assert_equal (7..22).to_a, ribbon.hours.map(&:hour)
  end

  test "places appointments and scheduled goals in their hour, empty elsewhere" do
    goal = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.new(2026, 8, 17), scheduled_hour: 9)
    appointment = Appointment.create!(title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 14, 30))

    ribbon = DayRibbon.new(goals: [ goal ], appointments: [ appointment ])
    by_hour = ribbon.hours.index_by(&:hour)

    assert_equal [ goal ], by_hour[9].goals
    assert_equal [], by_hour[9].appointments
    assert_equal [ appointment ], by_hour[14].appointments
    assert_equal [], by_hour[14].goals
    assert_equal [], by_hour[10].goals
  end

  test "sorts multiple appointments within the same hour by time" do
    later = Appointment.create!(title: "Later", starts_at: Time.zone.local(2026, 8, 17, 9, 45))
    earlier = Appointment.create!(title: "Earlier", starts_at: Time.zone.local(2026, 8, 17, 9, 15))

    ribbon = DayRibbon.new(goals: [], appointments: [ later, earlier ])
    assert_equal [ earlier, later ], ribbon.hours.index_by(&:hour)[9].appointments
  end

  test "goals without a scheduled_hour never appear in the ribbon" do
    Goal.create!(title: "Unscheduled", recurring: false, scheduled_on: Date.new(2026, 8, 17))

    ribbon = DayRibbon.new(goals: Goal.all, appointments: [])
    assert ribbon.hours.all? { |h| h.goals.empty? }
  end
end
