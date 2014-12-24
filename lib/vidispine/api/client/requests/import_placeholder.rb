module Vidispine::API::Client::Requests

  class ImportPlaceholder < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/import/placeholder'

    PARAMETERS = [
      { :name => :container, :required => true },
      { :name => :audio, :required => true },
      { :name => :video, :required => true },
      :type,
      :frameDuration,
      :notification,
      :notificationData,
      :priority,
      :jobmetadata,
      'no-transcode',
      { :name => :MetadataDocument, :aliases => [ :metadata ], :default_value => { }, :send_in => :body },
    ]

    def body
      @body ||= arguments[:MetadataDocument]
    end

    def body_as_xml
      <<-XML
<MetadataDocument xmlns="http://xml.vidispine.com/schema/vidispine">
</MetadataDocument>
      XML
    end

  end

end

