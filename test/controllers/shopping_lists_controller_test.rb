require "test_helper"

class ShoppingListsControllerTest < ActionDispatch::IntegrationTest
  test "creates a shopping list" do
    assert_difference("ShoppingList.count", 1) do
      post shopping_lists_path, params: { shopping_list: { name: "Courses hebdo" } }
    end
    assert_redirected_to shopping_list_path(ShoppingList.last)
  end

  test "invalid shopping list re-renders the form" do
    assert_no_difference("ShoppingList.count") do
      post shopping_lists_path, params: { shopping_list: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "renames a shopping list" do
    list = ShoppingList.create!(name: "Old name")
    patch shopping_list_path(list), params: { shopping_list: { name: "New name" } }
    assert_equal "New name", list.reload.name
  end

  test "destroys a shopping list" do
    list = ShoppingList.create!(name: "Temp")
    assert_difference("ShoppingList.count", -1) do
      delete shopping_list_path(list)
    end
  end

  test "adding, checking, and removing items never touches goals, points, or streaks" do
    list = ShoppingList.create!(name: "Courses hebdo")

    assert_difference("ShoppingListItem.count", 1) do
      assert_no_difference([ "GoalCompletion.count", "Goal.count" ]) do
        post shopping_list_shopping_list_items_path(list), params: { shopping_list_item: { name: "Pommes" } }
      end
    end

    item = list.shopping_list_items.sole
    assert_no_difference([ "GoalCompletion.count", "Goal.count" ]) do
      patch shopping_list_item_path(item), params: { shopping_list_item: { checked: true } }
    end
    assert item.reload.checked?
    assert_equal 0, GoalCompletion.sum(:points_awarded)

    assert_difference("ShoppingListItem.count", -1) do
      assert_no_difference([ "GoalCompletion.count", "Goal.count" ]) do
        delete shopping_list_item_path(item)
      end
    end
  end

  test "turbo_stream: creating an item replaces the items list in place" do
    list = ShoppingList.create!(name: "Courses hebdo")

    post shopping_list_shopping_list_items_path(list), params: { shopping_list_item: { name: "Pommes" } }, as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream", response.media_type
    assert_match "Pommes", response.body
  end

  test "turbo_stream: checking an item replaces the whole items container so the progress bar stays accurate" do
    list = ShoppingList.create!(name: "Courses hebdo")
    item = list.shopping_list_items.create!(name: "Pommes")

    patch shopping_list_item_path(item), params: { shopping_list_item: { checked: true } }, as: :turbo_stream

    assert_response :success
    assert_match "line-through", response.body
    assert_match "1/1", response.body
  end

  test "turbo_stream: deleting an item replaces the items container without it" do
    list = ShoppingList.create!(name: "Courses hebdo")
    item = list.shopping_list_items.create!(name: "Pommes")

    delete shopping_list_item_path(item), as: :turbo_stream

    assert_response :success
    assert_match "turbo-stream action=\"replace\" target=\"shopping_list_items\"", response.body
    assert_no_match "Pommes", response.body
  end
end
