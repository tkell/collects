class RemoveColorsFromReleases < ActiveRecord::Migration[7.1]
  def change
    remove_column :releases, :colors, :string
  end
end
