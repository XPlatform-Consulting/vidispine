module Vidispine::API::Client::Requests


  class ItemMetadataGet < BaseRequest
    # @see http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#get--item-(id)-metadata

    HTTP_METHOD = :get
    HTTP_PATH = '/item/#{path_arguments[:item_id]}/metadata'

    DEFAULT_PARAMETER_SEND_IN_VALUE = :matrix

    PARAMETERS = [
        { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path },

        :projection,
        :interval,
        :startc,
        :field,
        :group,
        :track,
        :language,
        :conflict,
        :samplerate,
        :revision,
        :terse,
        :include,
        :defaultValue,
        :from,
        :to,


        { :name => :includeTransientMetadata, :send_in => :query },

    ]

  end

end

