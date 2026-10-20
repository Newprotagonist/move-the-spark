require "test_helper"

class DemoResetJobTest < ActiveJob::TestCase
  test "réinitialise chaque compte démo sans toucher aux comptes normaux" do
    demo = User.create!(email_address: "demo@movethespark.app", password: "password", demo: true)
    demo.goals.create!(title: "Fouillis d'un visiteur", recurring: false, scheduled_on: Date.current)
    regular = users(:one)
    regular_goal_count = regular.goals.count

    DemoResetJob.perform_now

    assert_equal [ "Faire les courses", "Lire 20 minutes", "Méditer", "Sport" ], demo.goals.reload.pluck(:title).sort
    assert_equal regular_goal_count, regular.goals.reload.count
  end
end
