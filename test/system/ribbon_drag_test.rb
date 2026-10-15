require "application_system_test_case"

class RibbonDragTest < ApplicationSystemTestCase
  test "dragging a scheduled goal's ribbon card to a different half-hour slot reschedules it" do
    Goal.create!(user: @current_user, title: "Sport", recurring: true, frequency: "daily", active_from: Date.current, scheduled_hour: 9, scheduled_minute: 0)

    visit root_path
    within("#day-ribbon") { assert_text "Sport" }

    handle = find("[aria-label='Déplacer dans le ruban']")
    target_slot = find("[data-planning-hour-param='11'][data-planning-minute-param='30']")

    # Simulates the pointer gesture directly (Capybara has no high-level
    # helper for a custom pointer-event drag, only HTML5 native DnD) —
    # pointerdown on the handle, then pointermove/pointerup on window,
    # matching how planning_controller#dragStart attaches its listeners.
    page.execute_script(<<~JS, handle.native, target_slot.native)
      const [handle, targetSlot] = arguments
      const handleRect = handle.getBoundingClientRect()
      const targetRect = targetSlot.getBoundingClientRect()

      const fire = (type, target, clientY) =>
        target.dispatchEvent(new PointerEvent(type, { bubbles: true, cancelable: true, pointerId: 1, clientY }))

      fire("pointerdown", handle, handleRect.y + handleRect.height / 2)
      fire("pointermove", window, targetRect.y + targetRect.height / 2)
      fire("pointerup", window, targetRect.y + targetRect.height / 2)
    JS

    assert_text "11:30"
    goal = Goal.find_by(title: "Sport")
    assert_equal 11, goal.scheduled_hour
    assert_equal 30, goal.scheduled_minute
  end
end
