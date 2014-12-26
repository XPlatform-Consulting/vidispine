require 'logger'

require 'vidispine/api/client/http_client'
require 'vidispine/api/client/requests'

module Vidispine
  module API
    class Client

      attr_accessor :http_client, :request, :response

      def initialize(args = { })
        @http_client = HTTPClient.new(args)
      end

      def process_request(request, options = nil)
        @response = nil
        @request = request
        request.client = self unless request.client
        options ||= request.options
        @response = http_client.call_method(request.http_method, { :path => request.path, :query => request.query, :body => request.body }, options)
      end

      def process_request_using_class(request_class, args, options = { })
        @response = nil
        @request = request_class.new(args, options.merge(:client => self))
        process_request(request, options)
      end

      # Exposes HTTP Methods
      def http(method, *args)
        @request = nil
        @response = http_client.send(method, *args)
        @request = http_client.request
        response
      end

      # ############################################################################################################## #
      # @!group API Endpoints

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#create-a-collection
      def collection_create(args = { })
        collection_name = args.is_a?(String) ? args : begin
          _data = Requests::BaseRequest.process_parameters([ { :name => :name, :aliases => [ :collection_name ], :send_in => :query } ], args)
          _args = _data[:arguments_out]
          _args[:name]
        end
        http(:post, '/collection', '', :query => { :name => collection_name })
      end

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#delete-a-collection
      def collection_delete(args = { }, options = { })
        collection_id = args.is_a?(String) ? args : begin
          _data = Requests::BaseRequest.process_parameters([ { :name => :collection_id, :aliases => [ :id ] } ], args)
          _args = _data[:arguments_out]
          _args[:collection_id]
        end
        http(:delete, "/collection/#{collection_id}")
      end

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-the-contents-of-a-collection
      def collection_get(args = { }, options = { })
        collection_id = args.is_a?(String) ? args : begin
          _data = Requests::BaseRequest.process_parameters([ { :name => :collection_id, :aliases => [ :id ] } ], args)
          _args = _data[:arguments_out]
          _args[:collection_id]
        end
        http(:get, "/collection/#{collection_id}")
      end
      alias :collection :collection_get

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-the-items-of-a-collection
      def collection_items_get(args = { }, options = { })
        collection_id = args.is_a?(String) ? args : begin
          _data = Requests::BaseRequest.process_parameters([ { :name => :collection_id, :aliases => [ :id ] } ], args)
          _args = _data[:arguments_out]
          _args[:collection_id]
        end
        http(:get, "collection/#{collection_id}/item")
      end
      alias :collection_items :collection_items_get


      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-collection-metadata
      def collection_metadata_get(args = { }, options = { })
        collection_id = args.is_a?(String) ? args : begin
          _data = Requests::BaseRequest.process_parameters([ { :name => :collection_id, :aliases => [ :id ] } ], args)
          _args = _data[:arguments_out]
          _args[:collection_id]
        end
        http(:get, "/collection/#{collection_id}/metadata")
      end

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#add-an-item-library-or-collection-to-a-collection
      def collection_object_add(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'collection/#{path_arguments[:collection_id]}/#{path_arguments[:object_id]}',
            :http_method => :put,
            :parameters => [
              { :name => :collection_id, :required => true, :send_in => :path },
              { :name => :object_id,
                :aliases => [ :item_id, :library_id, :collection_to_add_id ], :required => true, :send_in => :path },
              { :name => :type, :aliases => [ :object_type ] },
              :addItems
            ],
          }.merge(options)
        )
        process_request(_request)
      end
      alias :collection_item_add :collection_object_add

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#remove-an-item-library-or-collection-from-a-collection
      def collection_object_remove(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'collection/#{path_arguments[:collection_id]}/#{path_arguments[:object_id]}',
            :http_method => :delete,
            :parameters => [
              { :name => :collection_id, :required => true, :send_in => :path },
              { :name => :object_id,
                :aliases => [ :item_id, :library_id, :collection_to_add_id ], :required => true, :send_in => :path },
              { :name => :type, :aliases => [ :object_type ] },
            ]
          }.merge(options)
        )
        process_request(_request)
      end
      alias :collection_item_remove :collection_object_remove

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#rename-a-collection
      # @param [Hash] args
      # @option args [String] :collection_id
      def collection_rename(args = { })
        _data = Requests::BaseRequest.process_parameters(
          [
            { :name => :collection_id, :aliases => [ :id ], :send_in => :path },
            { :name => :name, :aliases => [ :collection_name ] },
          ],
          args
        )
        _args = _data[:arguments_out]

        collection_id = CGI.escape(_args[:collection_id])
        name = _args[:name]

        http(:put, "collection/#{collection_id}/rename", '', :query => { :name => name }, :headers => { 'Content-Type' => 'text/plain' } )
      end

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-a-list-of-all-collections
      def collections_get
        http(:get, 'collection')
      end
      alias :collections :collections_get

      # @see http://apidoc.vidispine.com/latest/ref/item/import.html#create-a-placeholder-item
      def import_placeholder(args = { }, options = { })
        #query = options[:query] || { }
        # http(:post, '/import/placeholder', :query => query)
        process_request_using_class(Requests::ImportPlaceholder, args, options)
      end
      alias :placeholder_create :import_placeholder

      # @see http://apidoc.vidispine.com/latest/ref/item/import.html#import-to-a-placeholder-item
      def import_placeholder_item(args = { }, options = { })
        process_request_using_class(Requests::ImportPlaceholderItem, args, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/item/import.html#import-using-a-uri
      def import_using_uri(args = { }, options = { })
        process_request_using_class(Requests::ImportUsingURI, args, options)
      end
      alias :import :import_using_uri

      # @see http://apidoc.vidispine.com/4.2/ref/item/item.html#list-collections-that-contain-an-item
      def item_collections_get(args = { }, options = { })
        item_id = args.is_a?(String) ? args : begin
          _data = Requests::BaseRequest.process_parameters([ { :name => :item_id, :aliases => [ :id ] } ], args)
          _args = _data[:arguments_out]
          _args[:item_id]
        end
        http(:get, "/item/#{item_id}/collections")
      end
      alias :item_collections :item_collections_get

      # @see http://apidoc.vidispine.com/latest/ref/item/item.html#delete-a-single-item
      def item_delete(args = { }, options = { })
        process_request_using_class(Requests::ItemDelete, args, options)
      end

      # @see http://apidoc.vidispine.com/latest/ref/item/item.html#get-information-about-a-single-item
      def item_get(args = { }, options = { })
        # item_id = args.is_a?(String) ? args : begin
        #   _data = Requests::BaseRequest.process_parameters([ { :name => :item_id, :aliases => [ :id ] } ], args)
        #   _args = _data[:arguments_out]
        #   _args[:item_id]
        # end
        # http(:get, "/item/#{item_id}")

        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'item/#{path_arguments[:item_id]}',
            :parameters => [
              { :name => :item_id, :aliases => [ :id ], :send_in => :path, :required => true },
              { :name => :starttc, :send_in => :matrix },

              'noauth-url',
              'baseURI'
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#get--item-(id)-metadata
      def item_metadata_get(args = { }, options = { })
        process_request_using_class(Requests::ItemMetadataGet, args, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#add-a-metadata-change-set
      def item_metadata_set(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => '/item/#{arguments[:item_id]}/metadata',
            :http_method => :put,
            :parameters => [
              { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path },

              { :name => :projection, :send_in => :matrix },
              { :name => 'output-project', :send_in => :matrix },

              :revision,

              { :name => :MetadataDocument, :send_in => :body, :default => { } }
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/item/shape.html#get-files-for-shape
      def item_shape_files_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => '"/item/#{path_arguments[:item_id]}/shape/#{path_arguments[:shape_id]}/file"',
            :default_parameter_send_in_value => :path,
            :parameters => [
              :item_id,
              :shape_id
            ]
          }.merge(options)
        )
        process_request(_request)
      end
      alias :item_shape_files :item_shape_files_get

      # @see http://apidoc.vidispine.com/4.2/ref/item/shape.html#import-a-shape-using-a-uri-or-an-existing-file
      def item_shape_import(args = { }, options = { })
        # _request = Requests::BaseRequest.new(
        #   args,
        #   {
        #     :http_path => '"/item/#{item_id}/shape"',
        #     :parameters => [
        #       { :name => :item_id, :aliases => [ :id ], :send_in => :path },
        #       :uri,
        #       :fileId,
        #       { :name => :tag, :aliases => [ :tags ] },
        #       :settings,
        #       :notification,
        #       :notificationData,
        #       :priority,
        #       :jobmetadata
        #     ],
        #   }.merge(options)
        # )
        # process_request(_request)

        _data = Requests::BaseRequest.process_parameters(
          [
            { :name => :item_id, :aliases => [ :id ], :send_in => :path },
            :uri,
            :fileId,
            { :name => :tag, :aliases => [ :tags ] },
            :settings,
            :notification,
            :notificationData,
            :priority,
            :jobmetadata
          ],
          args
        )
        _args = _data[:arguments_out]

        item_id = _args[:item_id]
        uri = _args[:uri]
        file_id = _args[:fileId]
        tag = _args[:tag]
        tag = tag.join(',') if tag.is_a?(Array)
        settings = _args[:settings]
        notification = _args[:notification]
        notification_data = _args[:notificationData]
        priority = _args[:priority]
        job_metadata = _args[:jobmetadata]

        query = { }
        query[:uri] = uri if uri
        query[:fileId] = file_id if file_id
        query[:tag] = tag if tag
        query[:settings] = settings if settings
        query[:notification] = notification if notification
        query[:notificationData] = notification_data if notification_data
        query[:priority] = priority if priority
        query[:jobmetadata] = job_metadata if job_metadata

        http(:post, "/item/#{item_id}/shape", '', :query => query)
      end

      # @see http://apidoc.vidispine.com/latest/ref/item/thumbnail.html#start-a-thumbnail-job
      def item_thumbnail(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'item/#{path_arguments[:item_id]}/thumbnail',
            :http_method => :post,
            :parameters => [
              { :name => :item_id, :send_in => :path, :required => true },

              :createThumbnails,
              :createPosters,
              :thumbnailWidth,
              :thumbnailHeight,
              :thumbnailPeriod,
              :posterWidth,
              :posterHeight,
              :postFormat,
              :notification,
              :notificationData,
              :priority,
              :jobmetadata,
              :version,
              :sourceTag
            ]
          }.merge(options)
        )
        process_request(_request)
      end

        # @see http://apidoc.vidispine.com/4.2/ref/item/transcode.html#start-an-item-transcode-job
      def item_transcode(args = { }, options = { })
        process_request_using_class(Requests::ItemTranscode, args, options)
      end
      alias :item_create_thumbnail :item_transcode

      # @see http://apidoc.vidispine.com/4.2/ref/item-content.html#get--item-(item-id)-uri
      def item_uris_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => '/item/#{arguments[:item_id]}/uri',
            :parameters => [
              { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path },
              :type,
              { :name => :tag, :aliases => [ :tags ] },
              :scheme,
              :closedFiles
            ]
          }.merge(options)
        )
        process_request(_request)
      end
      alias :item_uri_get :item_uris_get
      alias :item_uris :item_uris_get
      alias :item_uri  :item_uris_get

      # @see http://apidoc.vidispine.com/latest/ref/item/item.html#retrieve-a-list-of-all-items
      def items_get(args = { }, options = { })
        #http(:get, 'item')
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'item',
            :default_parameter_send_in_value => :matrix,
            :parameters => [
              { :name => :result, :send_in => :query },
              { :name => :q, :send_in => :query },

              :library,
              :first,
              :number,
              :libraryId,
              :autoRefresh,
              :updateMode,
              :updateFrequency
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @see http://apidoc.vidispine.com/latest/ref/item/item.html#search-items
      def items_search(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'item',
            :http_method => :put,
            :default_parameter_send_in_value => :matrix,
            :parameters => [
              { :name => :result, :send_in => :query },

              :library,
              :first,
              :number,
              :libraryId,
              :autoRefresh,
              :updateMode,
              :updateFrequency,

              { :name => :ItemSearchDocument, :send_in => :body }
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/storage/storage.html#delete--storage-(storage-id)
      def storage_delete(args = { }, options = { })
        args = { :storage_id => args } if args.is_a?(String)
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'storage/#{path_arguments[:storage_id]}',
            :http_method => :delete,
            :parameters => [
              { :name => :storage_id, :aliases => [ :id ], :send_in => :path, :required => true },
              :safe
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/storage/file.html#list-files-in-storage
      def storage_file_get(args = { }, options = { })
        process_request_using_class(Requests::StorageFileGet, args, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/storage/storage.html#get--storage-(storage-id)
      def storage_get(args = { }, options = { })
        args = { :storage_id => args } if args.is_a?(String)
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'storage/#{path_arguments[:storage_id]}',
            :parameters => [
              { :name => :storage_id, :aliases => [ :id ], :send_in => :path, :required => true },
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/storage/storage.html#storage-methods
      def storage_method_get(args = { }, options = { })
        args = { :storage_id => args } if args.is_a?(String)
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'storage/#{path_arguments[:storage_id]}/method',
            :parameters => [
              { :name => :storage_id, :aliases => [ :id ], :send_in => :path, :required => true },

              { :name => :read, :send_in => :matrix },
              { :name => :write, :send_in => :matrix },
              { :name => :browse, :send_in => :matrix },

              :url,
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/storage/storage.html#retrieve-list-of-storages
      def storages_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'storage',
            :parameters => [
              :size,
              :freebytes,
              :usedbytes,
              :freeamount,
              :files,
              :storagegroup,
              :status
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @!endgroup API Endpoints
      # ############################################################################################################## #

      # Client
    end

    # API
  end

  # Vidispine
end