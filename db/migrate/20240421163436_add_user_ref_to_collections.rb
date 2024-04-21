class AddUserRefToCollections < ActiveRecord::Migration[7.1]
  def change
    add_reference :collections, :user, null: true, foreign_key: true
  end
end
