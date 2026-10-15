# Runs every 5 minutes (config/recurring.yml). Pushes a reminder once per
# appointment, exactly when its lead time is reached, guarded by
# reminder_sent_at so it never double-sends.
class AppointmentReminderJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      user.appointments.where(reminder_sent_at: nil).where("starts_at >= ?", Time.current).find_each do |appointment|
        next if appointment.reminder_due_at > Time.current

        PushSubscription.broadcast(
          user: user,
          title: "Rendez-vous à venir",
          body: reminder_body(appointment),
          path: Rails.application.routes.url_helpers.day_path(date: appointment.starts_at.to_date)
        )
        appointment.update!(reminder_sent_at: Time.current)
      end
    end
  end

  private

  def reminder_body(appointment)
    time = I18n.l(appointment.starts_at, format: :time_only)
    location = appointment.location.presence && " · #{appointment.location}"
    "#{appointment.title} à #{time}#{location}"
  end
end
