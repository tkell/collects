class AddNameAndIsStandardToVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :variants, :name, :string
    add_column :variants, :is_standard, :boolean
  end
end
