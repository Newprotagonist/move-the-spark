require "test_helper"

# Icon-only buttons in the app (goal checkbox, timer controls) rely on
# aria-label rather than visible text for their accessible name. Capybara
# only considers aria-label when this is enabled.
Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
end
