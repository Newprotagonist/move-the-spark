require "test_helper"

class HearthSceneTest < ActiveSupport::TestCase
  def counts_for(tier)
    HearthScene.for_tier(tier).layers.map(&:type).tally
  end

  test "tier 1 (Braise) is an ember bed with no flame yet" do
    counts = counts_for(1)
    assert_equal 5, counts[:coal]
    assert_equal 1, counts[:bed]
    assert_nil counts[:flame]
    assert_nil counts[:log]
    assert_nil counts[:stone]
  end

  test "tier 2 (Étincelle) adds a twinkling star and a single spark, still no flame" do
    counts = counts_for(2)
    assert_equal 1, counts[:star]
    assert_equal 1, counts[:spark]
    assert_nil counts[:flame]
  end

  test "tier 3 (Flammèche) is the first scene with a flame" do
    counts = counts_for(3)
    assert_equal 1, counts[:flame]
    assert_equal 2, counts[:spark]
    assert_nil counts[:log]
  end

  test "tier 4 (Ardeur) adds two logs" do
    counts = counts_for(4)
    assert_equal 1, counts[:flame]
    assert_equal 2, counts[:log]
    assert_nil counts[:stone]
  end

  test "tier 5 (Foyer) adds a ring of 5 stones" do
    counts = counts_for(5)
    assert_equal 1, counts[:flame]
    assert_equal 5, counts[:stone]
  end

  test "tier 6 (Brasier) has three flames and three logs" do
    counts = counts_for(6)
    assert_equal 3, counts[:flame]
    assert_equal 3, counts[:log]
    assert_equal 6, counts[:spark]
  end

  test "tier 7 (Phare) swaps the ember bed for a beam and a tower" do
    counts = counts_for(7)
    assert_equal 1, counts[:beam]
    assert_equal 1, counts[:tower]
    assert_equal 1, counts[:flame]
    assert_nil counts[:bed]
    assert_nil counts[:coal]
  end

  test "every tier has exactly one halo except tier 2 which has two" do
    (1..7).each do |tier|
      expected = tier == 2 ? 2 : 1
      assert_equal expected, counts_for(tier)[:halo], "tier #{tier}"
    end
  end

  test "out-of-range tiers clamp to the nearest real one" do
    assert_equal HearthScene.for_tier(1).layers, HearthScene.for_tier(0).layers
    assert_equal HearthScene.for_tier(1).layers, HearthScene.for_tier(-5).layers
    assert_equal HearthScene.for_tier(7).layers, HearthScene.for_tier(8).layers
    assert_equal HearthScene.for_tier(7).layers, HearthScene.for_tier(200).layers
  end
end
