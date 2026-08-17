class CreateShoppingLists < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_lists do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
