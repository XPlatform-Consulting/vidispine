module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/item/import.html#import-a-sidecar-file
  # @see http://vidispine.com/partner/vidiwiki/RestItemImport#Syntax:_Starting_a_sidecar_import_job
  class ImportSidecarFile < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/import/sidecar/#{path_arguments[:item_id]}'

    PARAMETERS = [
      { :name => :item_id, :required => true, :send_in => :path },
      :sidecar,
      :notification,
      :notificationDta,
      :priority,
      :jobmetadata,
    ]

    def after_process_parameters
      # URI Needs to be escaped twice, so we do it once here and then again when the query is built
      sidecar = arguments[:sidecar]
      arguments[:sidecar] = CGI.escape(sidecar) if sidecar and sidecar.start_with?('file://')
    end

  end

end

