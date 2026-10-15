class AddUserRefToPushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_reference :push_subscriptions, :user, null: true, foreign_key: true
  end
end
