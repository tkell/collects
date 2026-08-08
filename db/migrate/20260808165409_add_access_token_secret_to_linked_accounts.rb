class AddAccessTokenSecretToLinkedAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :linked_accounts, :access_token_secret, :string
  end
end
