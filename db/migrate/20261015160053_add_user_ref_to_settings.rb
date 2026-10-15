class AddUserRefToSettings < ActiveRecord::Migration[8.1]
  def change
    add_reference :settings, :user, null: true, foreign_key: true
  end
end
