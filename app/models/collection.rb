class Collection < ApplicationRecord
  belongs_to :user
  has_many :gardens, dependent: :destroy
  has_many :releases, dependent: :destroy
  has_many :release_sources, dependent: :destroy

  validates :user, presence: true

  def update_release_sources(overwrite_strategy)
    current_releases = releases.joins(:variants).pluck(:external_id, :colors).index_by {|r| r[0]}

    release_sources.each do | rs |
      rs.import_releases(overwrite_strategy, current_releases)
    end
  end
end
