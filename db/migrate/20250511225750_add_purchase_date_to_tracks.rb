class AddPurchaseDateToTracks < ActiveRecord::Migration[7.1]
  def change
    add_column :tracks, :purchase_date, :date
  end
end
