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

ActiveRecord::Schema[8.1].define(version: 2026_01_28_002201) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at", null: false
    t.integer "space_id", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["space_id"], name: "index_bookings_on_space_id"
    t.index ["starts_at"], name: "index_bookings_on_starts_at"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "model_id"
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_chats_on_model_id"
  end

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

  create_table "funding_opportunities", force: :cascade do |t|
    t.integer "amount"
    t.string "categories"
    t.datetime "created_at", null: false
    t.date "deadline", null: false
    t.text "description"
    t.string "organization", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["deadline"], name: "index_funding_opportunities_on_deadline"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expires_on"
    t.integer "membership_type", null: false
    t.text "notes"
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.integer "chat_id", null: false
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.integer "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.integer "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["model_id"], name: "index_messages_on_model_id"
    t.index ["role"], name: "index_messages_on_role"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "models", force: :cascade do |t|
    t.json "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.json "metadata", default: {}
    t.json "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.json "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["family"], name: "index_models_on_family"
    t.index ["provider", "model_id"], name: "index_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_models_on_provider"
  end

  create_table "newsletters", force: :cascade do |t|
    t.integer "chat_id"
    t.datetime "created_at", null: false
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_newsletters_on_chat_id"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.integer "membership_id", null: false
    t.text "notes"
    t.date "paid_on", null: false
    t.integer "payment_method", null: false
    t.datetime "updated_at", null: false
    t.index ["membership_id"], name: "index_payments_on_membership_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "location"
    t.string "name", null: false
    t.string "skills"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.boolean "visible", default: true, null: false
    t.string "website"
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tool_calls", force: :cascade do |t|
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.string "name", null: false
    t.string "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "spaces"
  add_foreign_key "bookings", "users"
  add_foreign_key "chats", "models"
  add_foreign_key "events", "users"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "models"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "newsletters", "chats"
  add_foreign_key "payments", "memberships"
  add_foreign_key "profiles", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tool_calls", "messages"
end
