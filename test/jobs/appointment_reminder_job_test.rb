require "test_helper"

class AppointmentReminderJobTest < ActiveJob::TestCase
  setup { @user = users(:one) }

  test "sends a push once an appointment reaches its reminder lead time and marks it sent" do
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    appointment = Appointment.create!(
      user: @user, title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30
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
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    appointment = Appointment.create!(
      user: @user, title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30
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
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Appointment.create!(user: @user, title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30)

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
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Appointment.create!(user: @user, title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30)

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 10, 5) do
        AppointmentReminderJob.perform_now
      end
    end

    assert_equal 0, calls.size
  end

  test "uses the owner's default lead time when the appointment has no override" do
    @user.setting.update!(default_appointment_lead_minutes: 15)
    PushSubscription.create!(user: @user, endpoint: "https://push.example/1", p256dh_key: "a", auth_key: "b")
    Appointment.create!(user: @user, title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0))

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 9, 46) do
        AppointmentReminderJob.perform_now
      end
    end

    assert_equal 1, calls.size
  end

  test "each user's due appointments only notify that user's own devices, and one user's reminder does not block another's" do
    other_user = users(:two)
    PushSubscription.create!(user: @user, endpoint: "https://push.example/mine", p256dh_key: "a", auth_key: "b")
    PushSubscription.create!(user: other_user, endpoint: "https://push.example/theirs", p256dh_key: "c", auth_key: "d")
    Appointment.create!(user: @user, title: "Dentiste", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30)
    Appointment.create!(user: other_user, title: "Coiffeur", starts_at: Time.zone.local(2026, 8, 17, 10, 0), reminder_lead_minutes: 30)

    calls = []
    Webpush.stub(:payload_send, ->(**kwargs) { calls << kwargs }) do
      travel_to Time.zone.local(2026, 8, 17, 9, 45) do
        AppointmentReminderJob.perform_now
      end
    end

    endpoints = calls.map { |c| c[:endpoint] }
    assert_includes endpoints, "https://push.example/mine"
    assert_includes endpoints, "https://push.example/theirs"
    assert_equal 2, calls.size
  end
end
