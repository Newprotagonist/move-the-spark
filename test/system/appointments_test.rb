require "application_system_test_case"

class AppointmentsTest < ApplicationSystemTestCase
  test "creating an appointment shows it in the combined day view" do
    visit root_path

    click_on "+ Rendez-vous"
    fill_in "Titre", with: "Dentiste"
    fill_in "Lieu (optionnel)", with: "Cabinet Dr. Martin"
    # `set` on a native datetime-local input simulates keystrokes, which can
    # land in the wrong sub-field (day/month/year) depending on locale.
    # Setting the value directly via JS is reliable regardless of locale.
    starts_at_value = "#{Date.current}T14:30"
    page.execute_script(
      "document.getElementById('appointment_starts_at').value = arguments[0]", starts_at_value
    )
    click_on "Ajouter au ruban"

    assert_text "Dentiste"
    assert_text "Cabinet Dr. Martin"
    assert_text "14:30"
  end
end
