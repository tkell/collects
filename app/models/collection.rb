class Collection < ApplicationRecord
  belongs_to :user
  has_many :gardens, dependent: :destroy
  has_many :releases, dependent: :destroy
  has_many :release_sources, dependent: :destroy

  validates :user, presence: true

  def update(overwrite_strategy)
    current_releases = releases.index_by(&:external_id)
    total_added = 0
    release_sources.each do | rs |
      added = rs.import_releases(overwrite_strategy, current_releases)
      total_added += added
    end

    self.level += total_added
    save!
  end
end
