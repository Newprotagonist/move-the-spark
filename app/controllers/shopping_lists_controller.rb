class ShoppingListsController < ApplicationController
  before_action :set_shopping_list, only: [ :show, :edit, :update, :destroy ]

  def index
    @shopping_lists = ShoppingList.ordered
  end

  def show
    @shopping_list_item = ShoppingListItem.new
  end

  def new
    @shopping_list = ShoppingList.new
  end

  def create
    @shopping_list = ShoppingList.new(shopping_list_params)
    if @shopping_list.save
      redirect_to @shopping_list, notice: "Liste créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @shopping_list.update(shopping_list_params)
      redirect_to @shopping_list, notice: "Liste mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shopping_list.destroy
    redirect_to shopping_lists_path, notice: "Liste supprimée."
  end

  private

  def set_shopping_list
    @shopping_list = ShoppingList.find(params[:id])
  end

  def shopping_list_params
    params.require(:shopping_list).permit(:name)
  end
end
