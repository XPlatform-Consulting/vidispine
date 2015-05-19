module Vidispine::API::Client::Requests


  # @see http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#set--item-(id)-metadata
  class ItemMetadataSet < BaseRequest

    HTTP_METHOD = :put
    HTTP_PATH = '/item/#{path_arguments[:item_id]}/metadata'

    PARAMETERS = [
      { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path },

      { :name => :projection, :send_in => :matrix },
      { :name => 'output-project', :send_in => :matrix },

      :revision,

      { :name => :MetadataDocument, :send_in => :body, :default_value => { } }
    ]

    def body
      @body ||= body_arguments[:MetadataDocument]
    end

  end


end

