module Vidispine::API::Client::Requests

  # Exposes two functions
  #   1. Get status of file in storage
  #     @see http://apidoc.vidispine.com/4.2.3/ref/storage/file.html#get-status-of-file-in-storage
  #
  #   2. Get direct download access to file in storage
  #     @see http://apidoc.vidispine.com/4.2.3/ref/storage/file.html#get-direct-download-access-to-file-in-storage
  class StorageFileGet < BaseRequest

    HTTP_PATH = '/storage/#{path_arguments[:storage_id]}/file/#{path_arguments[:file_id]}'

    PARAMETERS = [
      # Path Parameters
      { :name => :storage_id, :required => true, :send_in => :path },
      { :name => :file_id, :required => true, :send_in => :path },

      # Matrix Parameters
      { :name => :includeItem, :send_in => :matrix },
      { :name => :path, :send_in => :matrix },
      { :name => :uri, :send_in => :matrix },


      # Query Parameters
      :methodType
    ]

    def after_process_parameters
      # URI Needs to be escaped twice, so we do it once here and then again when the query is built
      _uri = arguments[:uri]
      arguments[:uri] = CGI.escape(_uri) if _uri
    end

  end

end
