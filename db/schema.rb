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

ActiveRecord::Schema[8.1].define(version: 2026_10_15_162829) do
  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location"
    t.text "notes"
    t.integer "reminder_lead_minutes"
    t.datetime "reminder_sent_at"
    t.datetime "starts_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["starts_at"], name: "index_appointments_on_starts_at"
    t.index ["user_id"], name: "index_appointments_on_user_id"
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
    t.integer "scheduled_hour"
    t.integer "scheduled_minute", default: 0, null: false
    t.date "scheduled_on"
    t.integer "scheduled_weekday"
    t.boolean "timed", default: true, null: false
    t.datetime "timer_paused_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["archived_at"], name: "index_goals_on_archived_at"
    t.index ["scheduled_on"], name: "index_goals_on_scheduled_on"
    t.index ["title"], name: "index_goals_on_title"
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.string "p256dh_key", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id", "endpoint"], name: "index_push_subscriptions_on_user_id_and_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "daily_goal_reminder_sent_on"
    t.time "daily_goal_reminder_time", default: "2000-01-01 18:00:00", null: false
    t.integer "default_appointment_lead_minutes", default: 30, null: false
    t.date "last_celebrated_on"
    t.integer "points_per_goal", default: 10, null: false
    t.integer "streak_bonus_cap", default: 10, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_settings_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "appointments", "users"
  add_foreign_key "goal_completions", "goals"
  add_foreign_key "goals", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "settings", "users"
end
