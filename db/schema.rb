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

ActiveRecord::Schema[8.1].define(version: 2026_02_02_011753) do
  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

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

  create_table "archived_emails", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "email_group_id", null: false
    t.string "from_address", null: false
    t.datetime "received_at", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["email_group_id"], name: "index_archived_emails_on_email_group_id"
    t.index ["received_at"], name: "index_archived_emails_on_received_at"
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

  create_table "email_group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "email_group_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["email_group_id", "user_id"], name: "index_email_group_memberships_on_email_group_id_and_user_id", unique: true
    t.index ["email_group_id"], name: "index_email_group_memberships_on_email_group_id"
    t.index ["user_id"], name: "index_email_group_memberships_on_user_id"
  end

  create_table "email_groups", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "local_part", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["local_part"], name: "index_email_groups_on_local_part", unique: true
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

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
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
    t.string "sumup_checkout_id"
    t.string "sumup_transaction_id"
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

  create_table "proposals", force: :cascade do |t|
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "funding_opportunity_id", null: false
    t.datetime "reviewed_at"
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["funding_opportunity_id"], name: "index_proposals_on_funding_opportunity_id"
    t.index ["user_id", "funding_opportunity_id"], name: "index_proposals_on_user_id_and_funding_opportunity_id", unique: true
    t.index ["user_id"], name: "index_proposals_on_user_id"
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

  create_table "thredded_categories", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "messageboard_id", null: false
    t.text "name", null: false
    t.text "slug", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["messageboard_id", "slug"], name: "index_thredded_categories_on_messageboard_id_and_slug", unique: true
    t.index ["messageboard_id"], name: "index_thredded_categories_on_messageboard_id"
    t.index ["name"], name: "thredded_categories_name_ci"
  end

  create_table "thredded_messageboard_groups", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.integer "position", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "thredded_messageboard_notifications_for_followed_topics", force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.integer "messageboard_id", null: false
    t.string "notifier_key", limit: 90, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "messageboard_id", "notifier_key"], name: "thredded_messageboard_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_messageboard_users", force: :cascade do |t|
    t.datetime "last_seen_at", precision: nil, null: false
    t.integer "thredded_messageboard_id", null: false
    t.integer "thredded_user_detail_id", null: false
    t.index ["thredded_messageboard_id", "last_seen_at"], name: "index_thredded_messageboard_users_for_recently_active"
    t.index ["thredded_messageboard_id", "thredded_user_detail_id"], name: "index_thredded_messageboard_users_primary", unique: true
  end

  create_table "thredded_messageboards", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "last_topic_id"
    t.boolean "locked", default: false, null: false
    t.integer "messageboard_group_id"
    t.text "name", null: false
    t.integer "position", null: false
    t.integer "posts_count", default: 0
    t.text "slug"
    t.integer "topics_count", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.index ["messageboard_group_id"], name: "index_thredded_messageboards_on_messageboard_group_id"
    t.index ["slug"], name: "index_thredded_messageboards_on_slug", unique: true
  end

  create_table "thredded_notifications_for_followed_topics", force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.string "notifier_key", limit: 90, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_followed_topics_unique", unique: true
  end

  create_table "thredded_notifications_for_private_topics", force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.string "notifier_key", limit: 90, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "notifier_key"], name: "thredded_notifications_for_private_topics_unique", unique: true
  end

  create_table "thredded_post_moderation_records", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "messageboard_id"
    t.integer "moderation_state", null: false
    t.integer "moderator_id"
    t.text "post_content", limit: 65535
    t.integer "post_id"
    t.integer "post_user_id"
    t.text "post_user_name"
    t.integer "previous_moderation_state", null: false
    t.index ["messageboard_id", "created_at"], name: "index_thredded_moderation_records_for_display", order: { created_at: :desc }
  end

  create_table "thredded_posts", force: :cascade do |t|
    t.text "content", limit: 65535
    t.datetime "created_at", precision: nil, null: false
    t.integer "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.integer "postable_id", null: false
    t.string "source", limit: 191, default: "web"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["messageboard_id"], name: "index_thredded_posts_on_messageboard_id"
    t.index ["moderation_state", "updated_at"], name: "index_thredded_posts_for_display"
    t.index ["postable_id", "created_at"], name: "index_thredded_posts_on_postable_id_and_created_at"
    t.index ["postable_id"], name: "index_thredded_posts_on_postable_id"
    t.index ["user_id"], name: "index_thredded_posts_on_user_id"
  end

  create_table "thredded_private_posts", force: :cascade do |t|
    t.text "content", limit: 65535
    t.datetime "created_at", precision: nil, null: false
    t.integer "postable_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["postable_id", "created_at"], name: "index_thredded_private_posts_on_postable_id_and_created_at"
  end

  create_table "thredded_private_topics", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "hash_id", limit: 20, null: false
    t.datetime "last_post_at", precision: nil
    t.integer "last_user_id"
    t.integer "posts_count", default: 0
    t.text "slug", null: false
    t.text "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["hash_id"], name: "index_thredded_private_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_private_topics_on_last_post_at"
    t.index ["slug"], name: "index_thredded_private_topics_on_slug", unique: true
  end

  create_table "thredded_private_users", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "private_topic_id"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["private_topic_id"], name: "index_thredded_private_users_on_private_topic_id"
    t.index ["user_id"], name: "index_thredded_private_users_on_user_id"
  end

  create_table "thredded_topic_categories", force: :cascade do |t|
    t.integer "category_id", null: false
    t.integer "topic_id", null: false
    t.index ["category_id"], name: "index_thredded_topic_categories_on_category_id"
    t.index ["topic_id"], name: "index_thredded_topic_categories_on_topic_id"
  end

  create_table "thredded_topics", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "hash_id", limit: 20, null: false
    t.datetime "last_post_at", precision: nil
    t.integer "last_user_id"
    t.boolean "locked", default: false, null: false
    t.integer "messageboard_id", null: false
    t.integer "moderation_state", null: false
    t.integer "posts_count", default: 0, null: false
    t.text "slug", null: false
    t.boolean "sticky", default: false, null: false
    t.text "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.index ["hash_id"], name: "index_thredded_topics_on_hash_id"
    t.index ["last_post_at"], name: "index_thredded_topics_on_last_post_at"
    t.index ["messageboard_id"], name: "index_thredded_topics_on_messageboard_id"
    t.index ["moderation_state", "sticky", "updated_at"], name: "index_thredded_topics_for_display", order: { sticky: :desc, updated_at: :desc }
    t.index ["slug"], name: "index_thredded_topics_on_slug", unique: true
    t.index ["user_id"], name: "index_thredded_topics_on_user_id"
  end

  create_table "thredded_user_details", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "last_seen_at", precision: nil
    t.datetime "latest_activity_at", precision: nil
    t.integer "moderation_state", default: 0, null: false
    t.datetime "moderation_state_changed_at", precision: nil
    t.integer "posts_count", default: 0
    t.integer "topics_count", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["latest_activity_at"], name: "index_thredded_user_details_on_latest_activity_at"
    t.index ["moderation_state", "moderation_state_changed_at"], name: "index_thredded_user_details_for_moderations", order: { moderation_state_changed_at: :desc }
    t.index ["user_id"], name: "index_thredded_user_details_on_user_id", unique: true
  end

  create_table "thredded_user_messageboard_preferences", force: :cascade do |t|
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.integer "messageboard_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "messageboard_id"], name: "thredded_user_messageboard_preferences_user_id_messageboard_id", unique: true
  end

  create_table "thredded_user_post_notifications", force: :cascade do |t|
    t.datetime "notified_at", precision: nil, null: false
    t.integer "post_id", null: false
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_thredded_user_post_notifications_on_post_id"
    t.index ["user_id", "post_id"], name: "index_thredded_user_post_notifications_on_user_id_and_post_id", unique: true
  end

  create_table "thredded_user_preferences", force: :cascade do |t|
    t.boolean "auto_follow_topics", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.boolean "follow_topics_on_mention", default: true, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_thredded_user_preferences_on_user_id", unique: true
  end

  create_table "thredded_user_private_topic_read_states", force: :cascade do |t|
    t.integer "integer", default: 0, null: false
    t.integer "postable_id", null: false
    t.datetime "read_at", precision: nil, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "user_id", null: false
    t.index ["user_id", "postable_id"], name: "thredded_user_private_topic_read_states_user_postable", unique: true
  end

  create_table "thredded_user_topic_follows", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "reason", limit: 1
    t.integer "topic_id", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "topic_id"], name: "thredded_user_topic_follows_user_topic", unique: true
  end

  create_table "thredded_user_topic_read_states", force: :cascade do |t|
    t.integer "integer", default: 0, null: false
    t.integer "messageboard_id", null: false
    t.integer "postable_id", null: false
    t.datetime "read_at", precision: nil, null: false
    t.integer "read_posts_count", default: 0, null: false
    t.integer "unread_posts_count", default: 0, null: false
    t.integer "user_id", null: false
    t.index ["messageboard_id"], name: "index_thredded_user_topic_read_states_on_messageboard_id"
    t.index ["user_id", "messageboard_id"], name: "thredded_user_topic_read_states_user_messageboard"
    t.index ["user_id", "postable_id"], name: "thredded_user_topic_read_states_user_postable", unique: true
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
  add_foreign_key "archived_emails", "email_groups"
  add_foreign_key "bookings", "spaces"
  add_foreign_key "bookings", "users"
  add_foreign_key "chats", "models"
  add_foreign_key "email_group_memberships", "email_groups"
  add_foreign_key "email_group_memberships", "users"
  add_foreign_key "events", "users"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "models"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "newsletters", "chats"
  add_foreign_key "payments", "memberships"
  add_foreign_key "profiles", "users"
  add_foreign_key "proposals", "funding_opportunities"
  add_foreign_key "proposals", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "thredded_messageboard_users", "thredded_messageboards", on_delete: :cascade
  add_foreign_key "thredded_messageboard_users", "thredded_user_details", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "thredded_posts", column: "post_id", on_delete: :cascade
  add_foreign_key "thredded_user_post_notifications", "users", on_delete: :cascade
  add_foreign_key "tool_calls", "messages"
end
