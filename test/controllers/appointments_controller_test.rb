require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  test "index lists upcoming appointments" do
    travel_to Time.zone.local(2026, 8, 17, 12, 0) do
      Appointment.create!(title: "Past rdv", starts_at: 1.day.ago)
      Appointment.create!(title: "Future rdv", starts_at: 1.day.from_now)

      get appointments_path

      assert_response :success
      assert_select "body", text: /Future rdv/
      assert_select "body", text: /Past rdv/, count: 0
    end
  end

  test "creates an appointment and redirects to the day it's on" do
    assert_difference("Appointment.count", 1) do
      post appointments_path, params: { appointment: { title: "Dentiste", starts_at: "2026-08-20T10:00", location: "Cabinet" } }
    end
    assert_redirected_to day_path(date: "2026-08-20")
  end

  test "invalid appointment re-renders the form" do
    assert_no_difference("Appointment.count") do
      post appointments_path, params: { appointment: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "updates an appointment" do
    appointment = Appointment.create!(title: "Old", starts_at: 1.day.from_now)
    patch appointment_path(appointment), params: { appointment: { title: "New" } }
    assert_equal "New", appointment.reload.title
  end

  test "destroys an appointment" do
    appointment = Appointment.create!(title: "Temp", starts_at: 1.day.from_now)
    assert_difference("Appointment.count", -1) do
      delete appointment_path(appointment)
    end
  end
end
