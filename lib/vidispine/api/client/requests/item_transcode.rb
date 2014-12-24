module Vidispine::API::Client::Requests

  class ItemTranscode < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/item/#{path_arguments[:item_id]}/transcode'

    PARAMETERS = [
      { :name => :item_id, :aliases => [ :id ], :send_in => :path, :required => true },

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

