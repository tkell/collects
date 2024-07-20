class AddTypeToAnnotations < ActiveRecord::Migration[7.1]
  def change
    add_column :annotations, :type, :integer
  end
end
