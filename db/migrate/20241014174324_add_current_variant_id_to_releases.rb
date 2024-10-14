class AddCurrentVariantIdToReleases < ActiveRecord::Migration[7.1]
  def change
    add_column :releases, :current_variant_id, :integer
    add_foreign_key :releases, :variants, column: :current_variant_id
  end
end
