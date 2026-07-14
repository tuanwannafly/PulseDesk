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

ActiveRecord::Schema[7.1].define(version: 2026_01_01_000007) do
  create_table "accounts", force: :cascade do |t|
    t.string "company_name", null: false
    t.string "subdomain", null: false
    t.string "plan", default: "free", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan"], name: "index_accounts_on_plan"
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_customers_on_account_id_and_email"
    t.index ["account_id"], name: "index_customers_on_account_id"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", null: false
    t.string "color", default: "#6b7280"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_tags_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_tags_on_account_id"
  end

  create_table "ticket_messages", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "ticket_id", null: false
    t.integer "user_id"
    t.integer "customer_id"
    t.string "sender_type", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "ticket_id", "created_at"], name: "idx_on_account_id_ticket_id_created_at_4d36ddaf01"
    t.index ["account_id"], name: "index_ticket_messages_on_account_id"
    t.index ["customer_id"], name: "index_ticket_messages_on_customer_id"
    t.index ["ticket_id"], name: "index_ticket_messages_on_ticket_id"
    t.index ["user_id"], name: "index_ticket_messages_on_user_id"
  end

  create_table "ticket_tags", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "ticket_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ticket_tags_on_account_id"
    t.index ["tag_id"], name: "index_ticket_tags_on_tag_id"
    t.index ["ticket_id", "tag_id"], name: "index_ticket_tags_on_ticket_id_and_tag_id", unique: true
    t.index ["ticket_id"], name: "index_ticket_tags_on_ticket_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "customer_id", null: false
    t.integer "assigned_to_id"
    t.string "subject", null: false
    t.text "body"
    t.string "status", default: "open", null: false
    t.string "priority", default: "normal", null: false
    t.text "ai_summary"
    t.float "sentiment_score"
    t.string "ai_suggested_priority"
    t.datetime "first_response_at"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "escalated_at"
    t.index ["account_id", "assigned_to_id"], name: "index_tickets_on_account_id_and_assigned_to_id"
    t.index ["account_id", "created_at"], name: "index_tickets_on_account_id_and_created_at"
    t.index ["account_id", "escalated_at"], name: "index_tickets_on_account_id_and_escalated_at"
    t.index ["account_id", "priority"], name: "index_tickets_on_account_id_and_priority"
    t.index ["account_id", "sentiment_score"], name: "index_tickets_on_account_id_and_sentiment_score"
    t.index ["account_id", "status"], name: "index_tickets_on_account_id_and_status"
    t.index ["account_id"], name: "index_tickets_on_account_id"
    t.index ["assigned_to_id"], name: "index_tickets_on_assigned_to_id"
    t.index ["customer_id"], name: "index_tickets_on_customer_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "agent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_users_on_account_id_and_email", unique: true
    t.index ["account_id", "role"], name: "index_users_on_account_id_and_role"
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  add_foreign_key "customers", "accounts"
  add_foreign_key "tags", "accounts"
  add_foreign_key "ticket_messages", "accounts"
  add_foreign_key "ticket_messages", "tickets"
  add_foreign_key "ticket_tags", "accounts"
  add_foreign_key "ticket_tags", "tags"
  add_foreign_key "ticket_tags", "tickets"
  add_foreign_key "tickets", "accounts"
  add_foreign_key "tickets", "customers"
  add_foreign_key "tickets", "users", column: "assigned_to_id"
  add_foreign_key "users", "accounts"
end
