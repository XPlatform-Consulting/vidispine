module Vidispine::API::Client::Requests

  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#delete--item-(item-id)-access-(access-id)
  # @see http://apidoc.vidispine.com/latest/ref/access-control.html#remove-all-access-control-entries-from-all-items
  class ItemAccessDelete < BaseRequest

    HTTP_METHOD = :delete
    HTTP_PATH = '/item/#{path_arguments[:item_id] ? "#{path_arguments[:item_id]}/" : ""}access/#{path_arguments[:access_id]}'

    PARAMETERS = [
      { :name => :item_id, :send_in => :path },
      { :name => :access_id, :send_in => :path, :required => true },
      { :name => :allow_all_items, :aliases => [ :all_items ], :send_in => :none }
    ]

    def after_process_parameters
      _item_id = arguments[:item_id]
      unless (arguments[:allow_all_items] == true) || (_item_id && !_item_id.empty?)
        raise ArgumentError, 'Item ID is required unless :allow_all_items parameter is set to true.'
      end
    end

  end

end

