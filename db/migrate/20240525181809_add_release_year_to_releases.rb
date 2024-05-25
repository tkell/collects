class AddReleaseYearToReleases < ActiveRecord::Migration[7.1]
  def change
    add_column :releases, :release_year, :integer
  end
end
