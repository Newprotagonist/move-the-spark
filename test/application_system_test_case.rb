require "test_helper"

# Icon-only buttons in the app (goal checkbox, timer controls) rely on
# aria-label rather than visible text for their accessible name. Capybara
# only considers aria-label when this is enabled.
Capybara.enable_aria_label = true

# The default 2s wait is tight for a full Turbo page navigation (not just a
# DOM update) on a loaded CI runner — bump it so genuinely slow CI doesn't
# flake tests that pass locally every time.
Capybara.default_max_wait_time = 5

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Unlike the controller-test sign_in_as helper (which manipulates a mock
  # cookie jar), this drives the real login form through the real browser —
  # SystemTestCase doesn't share IntegrationTest's session-stubbing machinery.
  def sign_in(user, password: "password")
    visit new_session_path
    fill_in "Identifiant", with: user.email_address
    fill_in "Mot de passe", with: password
    click_button "Se connecter"
    # The redirect after a successful login is Turbo-driven (async) — wait
    # for the login form to actually be gone before returning, otherwise
    # the caller's very next Capybara action can race the navigation.
    assert_no_selector "input[name='password']"
  end

  setup do
    @current_user = users(:one)
    sign_in(@current_user)
  end
end
