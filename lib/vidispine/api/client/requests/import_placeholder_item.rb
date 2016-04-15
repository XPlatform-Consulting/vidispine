module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/item/import.html#import-to-a-placeholder-item
  class ImportPlaceholderItem < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/import/placeholder/#{path_arguments[:item_id]}/#{path_arguments[:item_type]}'

    PARAMETERS = [
      { :name => :item_id, :required => true, :send_in => :path },
      { :name => :item_type, :required => true, :send_in => :path },
      :uri,
      :fileId,
      :tag,
      :original,
      :overrideFastStart,
      :requireFastStart,
      :fastStartLength,
      :growing,
      :notification,
      :notificationDta,
      :priority,
      :jobmetadata,
      :settings,
      :index
    ]

    def after_process_parameters
      # URI Needs to be escaped twice, so we do it once here and then again when the query is built
      _uri = arguments[:uri]
      arguments[:uri] = CGI.escape(_uri) if _uri
    end

  end

end

