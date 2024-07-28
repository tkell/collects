class AddPointsSpentToReleases < ActiveRecord::Migration[7.1]
  def change
    add_column :releases, :points_spent, :integer, default: 0
  end
end
