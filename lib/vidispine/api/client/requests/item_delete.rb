module Vidispine::API::Client::Requests

  class ItemDelete

    HTTP_METHOD = :delete
    HTTP_PATH = '/item/#{path_arguments[:item_id]}'

    PARAMETERS = [
      { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path },
      :keepShapeTagMedia,
      :keepShapeTagStorage,
    ]

  end

end

