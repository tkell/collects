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

ActiveRecord::Schema[7.1].define(version: 2024_07_28_011633) do
  create_table "annotations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "release_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "body"
    t.integer "annotation_type"
    t.index ["release_id"], name: "index_annotations_on_release_id"
    t.index ["user_id"], name: "index_annotations_on_user_id"
  end

  create_table "collections", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "level"
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "garden_releases", force: :cascade do |t|
    t.integer "release_id", null: false
    t.integer "garden_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["garden_id"], name: "index_garden_releases_on_garden_id"
    t.index ["release_id"], name: "index_garden_releases_on_release_id"
  end

  create_table "gardens", force: :cascade do |t|
    t.string "name"
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_gardens_on_collection_id"
  end

  create_table "playbacks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "release_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["release_id"], name: "index_playbacks_on_release_id"
    t.index ["user_id"], name: "index_playbacks_on_user_id"
  end

  create_table "releases", force: :cascade do |t|
    t.string "artist"
    t.string "title"
    t.string "label"
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.string "folder"
    t.string "colors"
    t.integer "release_year"
    t.date "purchase_date"
    t.integer "points", default: 0
    t.integer "points_spent", default: 0
    t.index ["collection_id"], name: "index_releases_on_collection_id"
    t.index ["external_id"], name: "index_releases_on_external_id", unique: true
  end

  create_table "tracks", force: :cascade do |t|
    t.string "title"
    t.string "media_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "release_id", null: false
    t.string "position"
    t.index ["release_id"], name: "index_tracks_on_release_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
  end

  add_foreign_key "annotations", "releases"
  add_foreign_key "annotations", "users"
  add_foreign_key "collections", "users"
  add_foreign_key "garden_releases", "gardens"
  add_foreign_key "garden_releases", "releases"
  add_foreign_key "gardens", "collections"
  add_foreign_key "playbacks", "releases"
  add_foreign_key "playbacks", "users"
  add_foreign_key "releases", "collections"
  add_foreign_key "tracks", "releases"
end
