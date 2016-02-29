module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/item/export.html#item-export
  class ItemExport < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/item/#{path_arguments[:item_id]}/export'
    DEFAULT_PARAMETER_SEND_IN_VALUE = :query

    PARAMETERS = [
      { :name => :item_id, :send_in => :path },

      :uri,
      :locationName,
      :tag,
      :metadata,
      :projection,
      :start,
      :end,
      :notification,
      :notificationData,
      :priority,
      :jobmetadata,
      :useOriginalFilename,
      :template,
      :allowMissing,

      { :name => :body, :send_in => :body }
    ]

    def body
      @body ||= arguments[:body]
    end

    def body_as_xml
      <<-XML
<empty/>
      XML
    end

  end

end

