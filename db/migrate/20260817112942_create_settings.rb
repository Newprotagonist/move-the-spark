class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.integer :points_per_goal, null: false, default: 10
      t.integer :default_appointment_lead_minutes, null: false, default: 30
      t.time :daily_goal_reminder_time, null: false, default: "18:00"
      t.date :daily_goal_reminder_sent_on

      t.timestamps
    end
  end
end
