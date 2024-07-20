class AddBodyToAnnotations < ActiveRecord::Migration[7.1]
  def change
    add_column :annotations, :body, :string
  end
end
