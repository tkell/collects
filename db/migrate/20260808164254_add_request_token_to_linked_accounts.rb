class AddRequestTokenToLinkedAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :linked_accounts, :request_token, :string
  end
end
