module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/4.2/ref/item/import.html#import-using-a-uri
  class ImportUsingURI < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/import'

    PARAMETERS = [
      { :name => :uri, :aliases => [ :url ], :required => true },
      :tag,
      :original,
      :thumbnails,
      :thumbnailService,
      :createPosers,
      :overrideFastStart,
      :requireFastStart,
      :fastStartLength,
      :storageId,
      :filename,
      :growing,
      :xmpfile,
      :sidecar,
      'no-transcode',
      :notification,
      :notificationData,
      :priority,
      :jobmetadata,
      { :name => :MetadataDocument, :aliases => [ :metadata ], :default_value => { }, :send_in => :body },
    ]

    def after_process_parameters
      # URI Needs to be escaped twice, so we do it once here and then again when the query is built
      _uri = arguments[:uri]
      arguments[:uri] = CGI.escape(_uri) if _uri
    end

  end

end
