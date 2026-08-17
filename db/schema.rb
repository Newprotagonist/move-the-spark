# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_17_114406) do
  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location"
    t.text "notes"
    t.integer "reminder_lead_minutes"
    t.datetime "reminder_sent_at"
    t.datetime "starts_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["starts_at"], name: "index_appointments_on_starts_at"
  end

  create_table "goal_completions", force: :cascade do |t|
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.integer "goal_id", null: false
    t.date "occurred_on", null: false
    t.integer "points_awarded", default: 0, null: false
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.index ["goal_id", "occurred_on"], name: "index_goal_completions_on_goal_id_and_occurred_on", unique: true
    t.index ["goal_id"], name: "index_goal_completions_on_goal_id"
  end

  create_table "goals", force: :cascade do |t|
    t.date "active_from"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "current_timer_started_at"
    t.text "description"
    t.string "frequency"
    t.integer "position", default: 0, null: false
    t.boolean "recurring", default: false, null: false
    t.date "scheduled_on"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_goals_on_archived_at"
    t.index ["scheduled_on"], name: "index_goals_on_scheduled_on"
    t.index ["title"], name: "index_goals_on_title"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "daily_goal_reminder_sent_on"
    t.time "daily_goal_reminder_time", default: "2000-01-01 18:00:00", null: false
    t.integer "default_appointment_lead_minutes", default: 30, null: false
    t.integer "points_per_goal", default: 10, null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopping_list_items", force: :cascade do |t|
    t.boolean "checked", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "shopping_list_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shopping_list_id"], name: "index_shopping_list_items_on_shopping_list_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "goal_completions", "goals"
  add_foreign_key "shopping_list_items", "shopping_lists"
end
