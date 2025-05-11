class CreateLinkedAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :linked_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.string :type

      t.timestamps
    end
  end
end
