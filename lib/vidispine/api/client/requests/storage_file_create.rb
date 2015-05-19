module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/4.2/ref/storage/file.html#list-files-in-storage
  class StorageFileCreate < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/storage/#{path_arguments[:storage_id]}/file'

    PARAMETERS = [
      # Path Parameters
      { :name => :storage_id, :required => true, :send_in => :path },

      # Query Parameters
      :createOnly,
      :state,

      # Body Parameters
      { :name => :path, :send_in => :body }
    ]
  end

end
