class FinalizeUserOwnership < ActiveRecord::Migration[8.1]
  def change
    change_column_null :goals, :user_id, false
    change_column_null :appointments, :user_id, false
    change_column_null :push_subscriptions, :user_id, false
    change_column_null :settings, :user_id, false

    remove_index :settings, :user_id
    add_index :settings, :user_id, unique: true

    remove_index :push_subscriptions, :endpoint, unique: true
    add_index :push_subscriptions, [ :user_id, :endpoint ], unique: true
  end
end
