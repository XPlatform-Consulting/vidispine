module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/item/item.html#search-items
  class ItemsSearch < BaseRequest

    HTTP_METHOD = :put
    HTTP_PATH = '/item'
    DEFAULT_PARAMETER_SEND_IN_VALUE = :matrix

    PARAMETERS = [
        { :name => :result, :send_in => :query },
        { :name => :content, :send_in => :query },


        :library,
        :first,
        :number,
        :libraryId,
        :autoRefresh,
        :updateMode,
        :updateFrequency,

        { :name => :ItemSearchDocument, :send_in => :body }
    ]

    def body
      @body ||= arguments[:ItemSearchDocument]
    end

    def body_as_xml
      <<-XML
<ItemSearchDocument xmlns="http://xml.vidispine.com/schema/vidispine">
</ItemSearchDocument>
      XML
    end

  end

end

