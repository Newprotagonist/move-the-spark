require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  test "requires a name" do
    list = ShoppingList.new
    assert_not list.valid?
    assert_includes list.errors.attribute_names, :name
  end

  test "destroying a list destroys its items" do
    list = ShoppingList.create!(name: "Courses hebdo")
    list.shopping_list_items.create!(name: "Pommes")

    assert_difference("ShoppingListItem.count", -1) do
      list.destroy
    end
  end

  test "is completely independent of goals, points and streaks" do
    ShoppingList.create!(name: "Courses hebdo").shopping_list_items.create!(name: "Pommes", checked: true)

    assert_equal 0, GoalCompletion.count
    assert_equal 0, GoalCompletion.sum(:points_awarded)
    assert_equal 0, StreakCalculator.new(unit: :day).current_streak
  end
end
