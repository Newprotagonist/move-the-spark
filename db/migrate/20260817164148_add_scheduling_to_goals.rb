class AddSchedulingToGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :goals, :scheduled_hour, :integer
    add_column :goals, :timed, :boolean, null: false, default: true
  end
end
