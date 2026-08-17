class ShoppingListItemsController < ApplicationController
  before_action :set_shopping_list, only: [ :create ]
  before_action :set_shopping_list_item, only: [ :update, :destroy ]

  def create
    @shopping_list_item = @shopping_list.shopping_list_items.build(shopping_list_item_params)
    @shopping_list_item.save

    respond_to do |format|
      format.html { redirect_to @shopping_list }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("shopping_list_items", partial: "shopping_lists/items", locals: { shopping_list: @shopping_list })
      end
    end
  end

  # Used both to toggle `checked` (from the list view) and to rename an item.
  # Replaces the whole items container (not just this row) so the progress
  # bar/fraction in its header — which depends on every item's checked
  # state — stays accurate.
  def update
    @shopping_list_item.update(shopping_list_item_params)
    shopping_list = @shopping_list_item.shopping_list

    respond_to do |format|
      format.html { redirect_to shopping_list }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("shopping_list_items", partial: "shopping_lists/items", locals: { shopping_list: shopping_list })
      end
    end
  end

  def destroy
    shopping_list = @shopping_list_item.shopping_list
    @shopping_list_item.destroy

    respond_to do |format|
      format.html { redirect_to shopping_list }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("shopping_list_items", partial: "shopping_lists/items", locals: { shopping_list: shopping_list })
      end
    end
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
