class ShoppingListItemsController < ApplicationController
  before_action :set_shopping_list, only: [ :create ]
  before_action :set_shopping_list_item, only: [ :update, :destroy ]

  def create
    @shopping_list_item = @shopping_list.shopping_list_items.build(shopping_list_item_params)
    @shopping_list_item.save
    redirect_to @shopping_list
  end

  # Used both to toggle `checked` (from the list view) and to rename an item.
  def update
    @shopping_list_item.update(shopping_list_item_params)
    redirect_to @shopping_list_item.shopping_list
  end

  def destroy
    shopping_list = @shopping_list_item.shopping_list
    @shopping_list_item.destroy
    redirect_to shopping_list
  end

  private

  def set_shopping_list
    @shopping_list = ShoppingList.find(params[:shopping_list_id])
  end

  def set_shopping_list_item
    @shopping_list_item = ShoppingListItem.find(params[:id])
  end

  def shopping_list_item_params
    params.require(:shopping_list_item).permit(:name, :checked)
  end
end
