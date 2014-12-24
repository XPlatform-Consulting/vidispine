module Vidispine::API::Client::Requests

  class ItemTranscode < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/item/#{path_arguments[:item_id]}/transcode'

    PARAMETERS = [
      { :name => :tag, :required => true },
      :createThumbnails,
      :createPosters,
      :notification,
      :notificationData,
      :priority,
      :jobmetadata
    ]

  end

end

