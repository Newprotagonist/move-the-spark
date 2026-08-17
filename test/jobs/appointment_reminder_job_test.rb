require "test_helper"

class AppointmentReminderJobTest < ActiveJob::TestCase
  test "sends a push once an appointment reaches its reminder lead time and marks it sent" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    appointment = Appointment.create!(
      title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30
    )

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 9, 30) do
        AppointmentReminderJob.perform_now
      end
    end

    assert_equal 1, calls.size
    assert_match "Dentiste", calls.first[:message]
    assert appointment.reload.reminder_sent_at.present?
  end

  test "does not send before the reminder lead time" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    appointment = Appointment.create!(
      title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30
    )

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 9, 0) do
        AppointmentReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
    assert_nil appointment.reload.reminder_sent_at
  end

  test "never sends the same appointment twice" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Appointment.create!(title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30)

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 9, 45) do
        AppointmentReminderJob.perform_now
        AppointmentReminderJob.perform_now
      end
    end

    assert_equal 1, calls.size
  end

  test "does not send for appointments that already started" do
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Appointment.create!(title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30)

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 10, 5) do
        AppointmentReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
  end

  test "uses the app-wide default lead time when the appointment has no override" do
    Setting.instance.update!(default_appointment_lead_minutes: 15)
    PushSubscription.create!(endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Appointment.create!(title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 9, 46) do
        AppointmentReminderJob.perform_now
      end
    end

    assert_equal 1, calls.size
  end
end
