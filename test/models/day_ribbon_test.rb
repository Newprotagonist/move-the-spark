require "test_helper"

class DayRibbonTest < ActiveSupport::TestCase
  test "slots span 07:00 to 22:30 in half-hour steps" do
    ribbon = DayRibbon.new(goals: [], appointments: [])
    expected = (7..22).flat_map { |hour| [ [ hour, 0 ], [ hour, 30 ] ] }
    assert_equal expected, ribbon.slots.map { |s| [ s.hour, s.minute ] }
  end

  test "places appointments and scheduled goals in their half-hour slot, empty elsewhere" do
    goal = Goal.create!(title: "Read", recurring: false, scheduled_on: Date.new(2026, 8, 17), scheduled_hour: 9, scheduled_minute: 30)
    appointment = Appointment.create!(title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 14, 30))

    ribbon = DayRibbon.new(goals: [ goal ], appointments: [ appointment ])
    by_slot = ribbon.slots.index_by { |s| [ s.hour, s.minute ] }

    assert_equal [ goal ], by_slot[[ 9, 30 ]].goals
    assert_equal [], by_slot[[ 9, 30 ]].appointments
    assert_equal [ appointment ], by_slot[[ 14, 30 ]].appointments
    assert_equal [], by_slot[[ 14, 30 ]].goals
    assert_equal [], by_slot[[ 9, 0 ]].goals
    assert_equal [], by_slot[[ 14, 0 ]].appointments
  end

  test "sorts multiple appointments within the same half-hour slot by time" do
    later = Appointment.create!(title: "Later", starts_at: Time.zone.local(2026, 8, 17, 9, 20))
    earlier = Appointment.create!(title: "Earlier", starts_at: Time.zone.local(2026, 8, 17, 9, 5))

    ribbon = DayRibbon.new(goals: [], appointments: [ later, earlier ])
    assert_equal [ earlier, later ], ribbon.slots.index_by { |s| [ s.hour, s.minute ] }[[ 9, 0 ]].appointments
  end

  test "goals without a scheduled_hour never appear in the ribbon" do
    Goal.create!(title: "Unscheduled", recurring: false, scheduled_on: Date.new(2026, 8, 17))

    ribbon = DayRibbon.new(goals: Goal.all, appointments: [])
    assert ribbon.slots.all? { |s| s.goals.empty? }
  end
end
