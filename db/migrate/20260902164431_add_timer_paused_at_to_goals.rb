class AddTimerPausedAtToGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :goals, :timer_paused_at, :datetime
  end
end
