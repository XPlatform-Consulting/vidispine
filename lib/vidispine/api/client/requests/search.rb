module Vidispine::API::Client::Requests

  class Search < BaseRequest

    HTTP_METHOD = :put
    HTTP_PATH = 'search'

    PARAMETERS = [
        :content,
        :interval,
        :field,
        :group,
        :language,
        :samplerate,
        :track,
        :terse,
        :include,
        :type,
        :tag,
        :scheme,
        :closedFiles,
        'noauth-url',
        :defaultValue,
        :methodType,
        :version,
        :revision,

        { :name => :first, :send_in => :matrix },

        { :name => :ItemSearchDocument, :default_value => { }, :send_in => :body },
    ]

    # {
    #   "field": [
    #     {
    #       "name": "portal_mf48881",
    #       "value": [
    #         {
    #           "value": "something"
    #         }
    #       ]
    #     }
    #   ]
    # }
    def body
      @body ||= arguments[:ItemSearchDocument]
    end

    def body_as_xml
      <<-XML
<ItemSearchDocument xmlns="http://xml.vidispine.com/schema/vidispine">
</ItemDocument>
      XML
    end

  end

end

