class AddImagePathSmallToVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :variants, :image_path_small, :string
  end
end
