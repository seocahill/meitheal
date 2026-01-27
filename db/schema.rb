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

ActiveRecord::Schema[8.1].define(version: 2026_01_27_221159) do
  create_table "events", force: :cascade do |t|
    t.text "bio"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "doors_at"
    t.datetime "ends_at"
    t.text "links"
    t.boolean "published", default: false, null: false
    t.datetime "starts_at", null: false
    t.integer "ticket_price_cents"
    t.string "ticket_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.text "venue_address"
    t.string "venue_name"
    t.index ["published"], name: "index_events_on_published"
    t.index ["starts_at"], name: "index_events_on_starts_at"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "events", "users"
  add_foreign_key "sessions", "users"
end
