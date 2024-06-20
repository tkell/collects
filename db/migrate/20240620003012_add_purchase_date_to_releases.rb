class AddPurchaseDateToReleases < ActiveRecord::Migration[7.1]
  def change
    add_column :releases, :purchase_date, :date
  end
end
