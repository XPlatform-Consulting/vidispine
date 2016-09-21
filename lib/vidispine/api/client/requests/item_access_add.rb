module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#add-a-new-entry-access-control-entry
  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#add-access-control-entries-to-all-items
  class ItemAccessAdd < BaseRequest

    HTTP_METHOD = :post
    HTTP_PATH = '/item/#{path_arguments[:item_id] ? "#{path_arguments[:item_id]}/" : ""}access'

    PARAMETERS = [
      { :name => :item_id, :send_in => :path },
      { :name => :access_control_document, :required => true, :send_in => :body },
      { :name => :allow_all_items, :aliases => [ :all_items ], :send_in => :none }
    ]

    def after_process_parameters
      _item_id = arguments[:item_id]
      unless (arguments[:allow_all_items] == true) || (_item_id && !_item_id.empty?)
        raise ArgumentError, 'Item ID is required unless :allow_all_items parameter is set to true.'
      end
    end

    def body
      body_arguments[:access_control_document]
    end

  end

end

