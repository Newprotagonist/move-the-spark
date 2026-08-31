require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "level_tier_name returns the right tier at each boundary" do
    assert_equal "Braise", level_tier_name(1)
    assert_equal "Braise", level_tier_name(2)
    assert_equal "Étincelle", level_tier_name(3)
    assert_equal "Étincelle", level_tier_name(5)
    assert_equal "Flammèche", level_tier_name(6)
    assert_equal "Flammèche", level_tier_name(10)
    assert_equal "Ardeur", level_tier_name(11)
    assert_equal "Ardeur", level_tier_name(20)
    assert_equal "Foyer", level_tier_name(21)
    assert_equal "Foyer", level_tier_name(40)
    assert_equal "Brasier", level_tier_name(41)
    assert_equal "Brasier", level_tier_name(80)
    assert_equal "Phare", level_tier_name(81)
    assert_equal "Phare", level_tier_name(200)
  end

  test "level_for_points, level_progress_percent, points_to_next_level are consistent" do
    assert_equal 1, level_for_points(0)
    assert_equal 0, level_progress_percent(0)
    assert_equal 100, points_to_next_level(0)

    assert_equal 5, level_for_points(420)
    assert_equal 20, level_progress_percent(420)
    assert_equal 80, points_to_next_level(420)
  end
end
