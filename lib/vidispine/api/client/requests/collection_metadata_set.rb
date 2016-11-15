module Vidispine::API::Client::Requests


  # @see http://apidoc.vidispine.com/4.2/ref/collection.html#update-collection-metadata
  class CollectionMetadataSet < BaseRequest

    HTTP_METHOD = :put
    HTTP_PATH = 'collection/#{path_arguments[:collection_id]}/metadata'

    PARAMETERS = [
      { :name => :collection_id, :aliases => [ :id ], :required => true, :send_in => :path },

      { :name => :MetadataDocument, :aliases => [ :body ], :send_in => :body, :default_value => { } }
    ]

    def body
      @body ||= body_arguments[:MetadataDocument]
    end

  end


end

