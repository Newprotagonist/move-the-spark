class CreateGoalCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_completions do |t|
      t.references :goal, null: false, foreign_key: true
      t.date :occurred_on, null: false
      t.datetime :completed_at, null: false
      t.datetime :started_at
      t.integer :duration_seconds
      t.integer :points_awarded, null: false, default: 0

      t.timestamps
    end

    add_index :goal_completions, [ :goal_id, :occurred_on ], unique: true
  end
end
