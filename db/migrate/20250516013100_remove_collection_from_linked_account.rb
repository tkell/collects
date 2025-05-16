class RemoveCollectionFromLinkedAccount < ActiveRecord::Migration[7.1]
  def change
    remove_reference :linked_accounts, :collection, null: false, foreign_key: true
  end
end
