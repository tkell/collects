class RenameTypeToAnnotationTypeInAnnotations < ActiveRecord::Migration[7.1]
  def change
    rename_column :annotations, :type, :annotation_type
  end
end
