require "application_system_test_case"

# Regression coverage for the nested-form bug: button_to renders its own
# <form>, and nesting one inside form_with is invalid HTML that made the
# browser submit the wrong (outer) form. Only catchable via a real click,
# never via a request spec hitting the route directly.
class DeleteViaEditFormTest < ApplicationSystemTestCase
  test "deleting a goal from its edit sheet actually deletes it" do
    Goal.create!(title: "À supprimer", recurring: true, frequency: "daily", active_from: Date.current)

    visit root_path
    click_link "Modifier"
    accept_confirm { click_on "Supprimer" }

    assert_no_text "À supprimer"
    assert_not Goal.exists?(title: "À supprimer")
  end

  test "deleting an appointment from its edit sheet actually deletes it" do
    Appointment.create!(title: "À annuler", starts_at: Time.current.change(hour: 14))

    # Not reachable from the day view's ribbon (read-only cards there, by
    # design) — the appointments index is where "Modifier" lives.
    visit appointments_path
    click_link "Modifier"
    accept_confirm { click_on "Supprimer" }

    assert_no_text "À annuler"
    assert_not Appointment.exists?(title: "À annuler")
  end
end
