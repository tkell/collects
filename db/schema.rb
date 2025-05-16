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

ActiveRecord::Schema[7.1].define(version: 2025_05_16_013550) do
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

  create_table "linked_accounts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.index ["user_id"], name: "index_linked_accounts_on_user_id"
  end

  create_table "playbacks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "release_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["release_id"], name: "index_playbacks_on_release_id"
    t.index ["user_id"], name: "index_playbacks_on_user_id"
  end

  create_table "release_sources", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "local_file_path"
    t.index ["collection_id"], name: "index_release_sources_on_collection_id"
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
    t.integer "release_year"
    t.date "purchase_date"
    t.integer "points", default: 0
    t.integer "points_spent", default: 0
    t.integer "current_variant_id"
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
    t.date "purchase_date"
    t.string "external_id"
    t.index ["release_id"], name: "index_tracks_on_release_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
  end

  create_table "variants", force: :cascade do |t|
    t.string "image_path"
    t.integer "release_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "colors"
    t.string "name"
    t.boolean "is_standard"
    t.index ["release_id"], name: "index_variants_on_release_id"
  end

  add_foreign_key "annotations", "releases"
  add_foreign_key "annotations", "users"
  add_foreign_key "collections", "users"
  add_foreign_key "garden_releases", "gardens"
  add_foreign_key "garden_releases", "releases"
  add_foreign_key "gardens", "collections"
  add_foreign_key "linked_accounts", "users"
  add_foreign_key "playbacks", "releases"
  add_foreign_key "playbacks", "users"
  add_foreign_key "release_sources", "collections"
  add_foreign_key "releases", "collections"
  add_foreign_key "releases", "variants", column: "current_variant_id"
  add_foreign_key "tracks", "releases"
  add_foreign_key "variants", "releases"
end
