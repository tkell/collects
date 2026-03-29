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

ActiveRecord::Schema[7.1].define(version: 2026_03_29_020445) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "annotations", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "release_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "body"
    t.bigint "annotation_type"
    t.index ["release_id"], name: "idx_16436_index_annotations_on_release_id"
    t.index ["user_id"], name: "idx_16436_index_annotations_on_user_id"
  end

  create_table "collections", force: :cascade do |t|
    t.text "name"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.bigint "user_id"
    t.bigint "level"
    t.index ["user_id"], name: "idx_16424_index_collections_on_user_id"
  end

  create_table "garden_releases", force: :cascade do |t|
    t.bigint "release_id"
    t.bigint "garden_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["garden_id"], name: "idx_16412_index_garden_releases_on_garden_id"
    t.index ["release_id"], name: "idx_16412_index_garden_releases_on_release_id"
  end

  create_table "gardens", force: :cascade do |t|
    t.text "name"
    t.bigint "collection_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["collection_id"], name: "idx_16398_index_gardens_on_collection_id"
  end

  create_table "linked_accounts", force: :cascade do |t|
    t.bigint "user_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "provider"
    t.text "access_token"
    t.text "refresh_token"
    t.timestamptz "expires_at"
    t.index ["user_id"], name: "idx_16466_index_linked_accounts_on_user_id"
  end

  create_table "playbacks", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "release_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.index ["release_id"], name: "idx_16431_index_playbacks_on_release_id"
    t.index ["user_id"], name: "idx_16431_index_playbacks_on_user_id"
  end

  create_table "release_sources", force: :cascade do |t|
    t.bigint "collection_id"
    t.text "type"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "local_file_path"
    t.index ["collection_id"], name: "idx_16459_index_release_sources_on_collection_id"
  end

  create_table "releases", force: :cascade do |t|
    t.text "artist"
    t.text "title"
    t.text "label"
    t.bigint "collection_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "external_id"
    t.text "folder"
    t.bigint "release_year"
    t.date "purchase_date"
    t.bigint "points", default: 0
    t.bigint "points_spent", default: 0
    t.bigint "current_variant_id"
    t.index ["collection_id"], name: "idx_16450_index_releases_on_collection_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.text "title"
    t.text "media_link"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.bigint "release_id"
    t.text "position"
    t.date "purchase_date"
    t.text "external_id"
    t.index ["release_id"], name: "idx_16405_index_tracks_on_release_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "email"
    t.text "username"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "password_digest"
    t.text "email_verification_token"
    t.timestamptz "email_verified_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.index ["email_verification_token"], name: "idx_16417_index_users_on_email_verification_token", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
  end

  create_table "variants", force: :cascade do |t|
    t.text "image_path"
    t.bigint "release_id"
    t.timestamptz "created_at"
    t.timestamptz "updated_at"
    t.text "colors"
    t.text "name"
    t.boolean "is_standard"
    t.index ["release_id"], name: "idx_16443_index_variants_on_release_id"
  end

  add_foreign_key "annotations", "releases", name: "annotations_release_id_fkey"
  add_foreign_key "annotations", "users", name: "annotations_user_id_fkey"
  add_foreign_key "collections", "users", name: "collections_user_id_fkey"
  add_foreign_key "garden_releases", "gardens", name: "garden_releases_garden_id_fkey"
  add_foreign_key "garden_releases", "releases", name: "garden_releases_release_id_fkey"
  add_foreign_key "gardens", "collections", name: "gardens_collection_id_fkey"
  add_foreign_key "linked_accounts", "users", name: "linked_accounts_user_id_fkey"
  add_foreign_key "playbacks", "releases", name: "playbacks_release_id_fkey"
  add_foreign_key "playbacks", "users", name: "playbacks_user_id_fkey"
  add_foreign_key "release_sources", "collections", name: "release_sources_collection_id_fkey"
  add_foreign_key "releases", "collections", name: "releases_collection_id_fkey"
  add_foreign_key "releases", "variants", column: "current_variant_id", name: "releases_current_variant_id_fkey"
  add_foreign_key "tracks", "releases", name: "tracks_release_id_fkey"
  add_foreign_key "variants", "releases", name: "variants_release_id_fkey"
end
