require "application_system_test_case"

# Selenium has no native touch-gesture simulation, so these dispatch real
# TouchEvent/Touch objects via execute_script instead of driving the
# controller through Capybara's own (mouse-only) click/drag API — the only
# way to actually exercise touchstart/touchmove/touchend end-to-end here.
class SwipeNavTest < ApplicationSystemTestCase
  def swipe(dx)
    page.execute_script(<<~JS)
      const el = document.querySelector('[data-controller="swipe-nav"]');
      function touch(type, x) {
        const t = new Touch({ identifier: 1, target: el, clientX: x, clientY: 400 });
        const ev = new TouchEvent(type, { touches: type === 'touchend' ? [] : [t], targetTouches: [], changedTouches: [t], bubbles: true, cancelable: true });
        el.dispatchEvent(ev);
      }
      touch('touchstart', 300);
      touch('touchmove', 300 - #{dx / 2});
      touch('touchmove', 300 - #{dx});
      touch('touchend', 300 - #{dx});
    JS
  end

  test "swiping left on the day view navigates to the next day" do
    visit day_path(date: "2026-08-17")

    swipe(150)
    sleep 0.3

    assert_equal day_path(date: "2026-08-18"), current_path
  end

  test "swiping right on the day view navigates to the previous day" do
    visit day_path(date: "2026-08-17")

    swipe(-150)
    sleep 0.3

    assert_equal day_path(date: "2026-08-16"), current_path
  end

  test "a short swipe below the distance threshold does not navigate" do
    visit day_path(date: "2026-08-17")

    swipe(20)
    sleep 0.3

    assert_equal day_path(date: "2026-08-17"), current_path
  end

  test "swiping on the week view navigates to the next week" do
    monday = Date.new(2026, 8, 17)
    visit week_path(date: monday)

    swipe(150)
    sleep 0.3

    assert_equal week_path(date: monday + 7), current_path
  end
end
