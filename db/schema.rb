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

ActiveRecord::Schema.define(version: 2024_01_01_000004) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "shipments", force: :cascade do |t|
    t.string "reference_number", null: false
    t.string "origin", null: false
    t.string "destination", null: false
    t.string "carrier"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["reference_number"], name: "index_shipments_on_reference_number", unique: true
  end

  create_table "tracking_events", force: :cascade do |t|
    t.bigint "shipment_id", null: false
    t.integer "status", null: false
    t.string "location"
    t.datetime "occurred_at", null: false
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["shipment_id"], name: "index_tracking_events_on_shipment_id"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.bigint "webhook_endpoint_id", null: false
    t.bigint "tracking_event_id", null: false
    t.jsonb "payload", null: false
    t.integer "response_code"
    t.text "response_body"
    t.integer "status", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "delivered_at"
    t.datetime "next_retry_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["tracking_event_id"], name: "index_webhook_deliveries_on_tracking_event_id"
    t.index ["webhook_endpoint_id", "created_at"], name: "index_webhook_deliveries_on_webhook_endpoint_id_and_created_at"
    t.index ["webhook_endpoint_id"], name: "index_webhook_deliveries_on_webhook_endpoint_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.string "url", null: false
    t.string "secret", null: false
    t.bigint "shipment_id"
    t.string "status_filters", default: [], array: true
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["shipment_id"], name: "index_webhook_endpoints_on_shipment_id"
  end

  add_foreign_key "tracking_events", "shipments"
  add_foreign_key "webhook_deliveries", "tracking_events"
  add_foreign_key "webhook_deliveries", "webhook_endpoints"
  add_foreign_key "webhook_endpoints", "shipments"
end
