require "test_helper"

class ShoppingListItemTest < ActiveSupport::TestCase
  test "requires a name and a shopping list" do
    item = ShoppingListItem.new
    assert_not item.valid?
    assert_includes item.errors.attribute_names, :name
    assert_includes item.errors.attribute_names, :shopping_list
  end

  test "checked defaults to false" do
    list = ShoppingList.create!(name: "Courses hebdo")
    item = list.shopping_list_items.create!(name: "Pommes")
    assert_not item.checked?
  end
end
