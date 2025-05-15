class AddOAuthFieldsToLinkedAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :linked_accounts, :provider, :string
    add_column :linked_accounts, :access_token, :string
    add_column :linked_accounts, :refresh_token, :string
    add_column :linked_accounts, :expires_at, :datetime
  end
end
