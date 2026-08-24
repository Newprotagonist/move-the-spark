class AddScheduledWeekdayToGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :goals, :scheduled_weekday, :integer
  end
end
