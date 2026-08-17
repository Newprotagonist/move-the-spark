# Independent utility feature: shopping lists have no relation whatsoever to
# goals/points/streaks. See ShoppingListTest for an explicit assertion of
# that isolation.
class ShoppingList < ApplicationRecord
  has_many :shopping_list_items, -> { order(:position, :created_at) }, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
