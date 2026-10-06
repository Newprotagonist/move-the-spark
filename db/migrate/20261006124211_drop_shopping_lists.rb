class DropShoppingLists < ActiveRecord::Migration[8.1]
  def change
    drop_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :checked, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    drop_table :shopping_lists do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
