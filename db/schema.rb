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

ActiveRecord::Schema[7.1].define(version: 2023_12_07_025056) do
  create_table "collections", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "garden_items", force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "garden_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["garden_id"], name: "index_garden_items_on_garden_id"
    t.index ["item_id"], name: "index_garden_items_on_item_id"
  end

  create_table "gardens", force: :cascade do |t|
    t.string "name"
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_gardens_on_collection_id"
  end

  create_table "gardens_items", id: false, force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "garden_id", null: false
    t.index ["garden_id", "item_id"], name: "index_gardens_items_on_garden_id_and_item_id"
    t.index ["item_id", "garden_id"], name: "index_gardens_items_on_item_id_and_garden_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "artist"
    t.string "title"
    t.string "label"
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["collection_id"], name: "index_items_on_collection_id"
  end

  create_table "subitems", force: :cascade do |t|
    t.string "title"
    t.string "media_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "item_id", null: false
    t.integer "number"
    t.index ["item_id"], name: "index_subitems_on_item_id"
  end

  add_foreign_key "garden_items", "gardens"
  add_foreign_key "garden_items", "items"
  add_foreign_key "gardens", "collections"
  add_foreign_key "items", "collections"
  add_foreign_key "subitems", "items"
end
