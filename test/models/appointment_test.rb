require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  test "requires a title and starts_at" do
    appointment = Appointment.new
    assert_not appointment.valid?
    assert_includes appointment.errors.attribute_names, :title
    assert_includes appointment.errors.attribute_names, :starts_at
  end

  test "upcoming excludes past appointments and orders by starts_at" do
    travel_to Time.zone.local(2026, 8, 17, 12, 0) do
      past = Appointment.create!(title: "Past", starts_at: 1.hour.ago)
      later = Appointment.create!(title: "Later today", starts_at: 3.hours.from_now)
      soon = Appointment.create!(title: "Soon", starts_at: 1.hour.from_now)

      assert_equal [ soon, later ], Appointment.upcoming.to_a
    end
  end

  test "on_date scopes to a single calendar day" do
    Appointment.create!(title: "Today morning", starts_at: Time.zone.local(2026, 8, 17, 9, 0))
    Appointment.create!(title: "Tomorrow", starts_at: Time.zone.local(2026, 8, 18, 9, 0))

    result = Appointment.on_date(Date.new(2026, 8, 17))
    assert_equal [ "Today morning" ], result.map(&:title)
  end

  test "in_week scopes to the Monday-based week containing the date" do
    Appointment.create!(title: "This monday", starts_at: Time.zone.local(2026, 8, 17, 9, 0))
    Appointment.create!(title: "This sunday", starts_at: Time.zone.local(2026, 8, 23, 20, 0))
    Appointment.create!(title: "Next week", starts_at: Time.zone.local(2026, 8, 24, 9, 0))

    result = Appointment.in_week(Date.new(2026, 8, 19))
    assert_equal [ "This monday", "This sunday" ], result.map(&:title)
  end

  test "effective_reminder_lead_minutes falls back to the app-wide setting" do
    Setting.instance.update!(default_appointment_lead_minutes: 45)
    appointment = Appointment.create!(title: "Dentist", starts_at: 1.day.from_now)
    assert_equal 45, appointment.effective_reminder_lead_minutes

    appointment.update!(reminder_lead_minutes: 10)
    assert_equal 10, appointment.effective_reminder_lead_minutes
  end

  test "reminder_due_at is starts_at minus the effective lead time" do
    appointment = Appointment.create!(title: "Dentist", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30)
    assert_equal Time.zone.local(2026, 8, 17, 9, 30), appointment.reminder_due_at
  end
end
