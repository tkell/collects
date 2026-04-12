class CollectionImportChannel < ApplicationCable::Channel
  def subscribed
    stream_from "collection_import_#{params[:collection_id]}"
  end

  def unsubscribed
  end
end
