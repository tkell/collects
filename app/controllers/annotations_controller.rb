class AnnotationsController < ApplicationController
  # per-release
  def index
    @release = Release.where(id: params['release_id']).includes(:tracks).first
    @annotations = Annotation.where(release_id: @release.id)
  end
end
