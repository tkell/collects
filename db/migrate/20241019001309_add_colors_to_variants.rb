class AddColorsToVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :variants, :colors, :string
  end
end
