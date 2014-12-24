module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/item/import.html#import-to-a-placeholder-item
  class ImportPlaceholderItem < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/import/placeholder/#{path_arguments[:item_id]}/#{path_arguments[:item_type]}'

    PARAMETERS = [
      { :name => :item_id, :required => true },
      { :name => :item_type, :required => true },
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
      arguments[:uri] = CGI.escape(arguments[:uri])
    end

  end

end

