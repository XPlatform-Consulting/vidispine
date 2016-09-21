module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#add-a-new-entry-access-control-entry
  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#add-access-control-entries-to-all-items
  class CollectionAccessAdd < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/collection/#{path_arguments[:collection_id] ? "#{path_arguments[:collection_id]}/" : ""}access'

    PARAMETERS = [
        { :name => :collection_id, :send_in => :path },
        { :name => :access_control_document, :required => true, :send_in => :body },
        { :name => :allow_all_collections, :aliases => [ :all_collections ], :send_in => :none }
    ]

    def after_process_parameters
      _collection_id = arguments[:collection_id]
      unless (arguments[:allow_all_collections] == true) || (_collection_id && !_collection_id.empty?)
        raise ArgumentError, 'Collection ID is required unless :allow_all_collections parameter is set to true.'
      end
    end

    def body
      body_arguments[:access_control_document]
    end

  end

end

