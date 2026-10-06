class AddScheduledMinuteToGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :goals, :scheduled_minute, :integer, default: 0, null: false
  end
end
