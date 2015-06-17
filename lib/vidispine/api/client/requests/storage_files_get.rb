module Vidispine::API::Client::Requests

  class StorageFilesGet < BaseRequest
    # @see http://apidoc.vidispine.com/4.2/ref/storage/file.html#list-files-in-storage

    HTTP_PATH = '/storage/#{path_arguments[:storage_id]}/file'

    PARAMETERS = [
      # Path Parameters
      { :name => :storage_id, :required => true, :send_in => :path },

      # Matrix Parameters
      { :name => :start, :send_in => :matrix },
      { :name => :number, :send_in => :matrix },
      { :name => :filter, :send_in => :matrix },
      { :name => :includeItem, :send_in => :matrix },
      { :name => :excludeQueued, :send_in => :matrix },
      { :name => :ignorecase, :send_in => :matrix },
      { :name => :sort, :send_in => :matrix },
      { :name => :storage, :send_in => :matrix },

      # Query Parameters
      :path,
      :id,
      :recursive,
      :wildcard,
      :type,
      :hash,
      :algorithm,
      :count,
    ]

    def after_process_parameters
      # Path Needs to be escaped twice, so we do it once here and then again when the query is built
      # @see http://apidoc.vidispine.com/4.2.6/storage/uri.html#api-calls
      _path = arguments[:path]
      arguments[:path] = CGI.escape(_path).gsub('+', '%20') if _path
    end

  end

end
