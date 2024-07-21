class Annotation < ApplicationRecord
  validates :body, presence: true, length: { minimum: 1 }
  enum :annotation_type, [:genre, :vibe, :epoch, :freeform]

  belongs_to :user
  belongs_to :release
end
