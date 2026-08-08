class AddRequestTokenSecretToLinkedAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :linked_accounts, :request_token_secret, :string
  end
end
