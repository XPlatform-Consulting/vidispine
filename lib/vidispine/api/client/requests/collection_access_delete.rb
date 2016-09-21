module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#delete--collection-(collection-id)-access-(access-id)
  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#remove-all-access-control-entries-from-all-collections
  class CollectionAccessDelete < BaseRequest

    HTTP_METHOD = :delete
    HTTP_PATH = '/collection/#{path_arguments[:collection_id] ? "#{path_arguments[:collection_id]}/" : ""}access/#{path_arguments[:access_id]}'

    PARAMETERS = [
      { :name => :collection_id, :send_in => :path },
      { :name => :access_id, :send_in => :path, :required => true },
      { :name => :allow_all_collections, :aliases => [ :all_collections ], :send_in => :none }
    ]

    def after_process_parameters
      _collection_id = arguments[:collection_id]
      unless (arguments[:allow_all_collections] == true) || (_collection_id && !_collection_id.empty?)
        raise ArgumentError, 'Collection ID is required unless :allow_all_collections parameter is set to true.'
      end
    end

  end

end

