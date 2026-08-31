class AddLastCelebratedOnToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :last_celebrated_on, :date
  end
end
