class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.string :title, null: false
      t.text :description
      t.string :frequency
      t.boolean :recurring, null: false, default: false
      t.date :scheduled_on
      t.date :active_from
      t.datetime :archived_at
      t.datetime :current_timer_started_at
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :goals, :archived_at
    add_index :goals, :scheduled_on
    add_index :goals, :title
  end
end
