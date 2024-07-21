class Annotation < ApplicationRecord
  enum :annotation_type, [:genre, :vibe, :epoch, :freeform]

  belongs_to :user
  belongs_to :release
end
