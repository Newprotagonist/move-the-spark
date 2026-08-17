class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.string :location
      t.text :notes
      t.integer :reminder_lead_minutes
      t.datetime :reminder_sent_at

      t.timestamps
    end

    add_index :appointments, :starts_at
  end
end
