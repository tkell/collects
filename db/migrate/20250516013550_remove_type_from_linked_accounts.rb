class RemoveTypeFromLinkedAccounts < ActiveRecord::Migration[7.1]
  def change
    remove_column :linked_accounts, :type, :string
  end
end
