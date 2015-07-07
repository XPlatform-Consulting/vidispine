require 'logger'

require 'vidispine/api/client/http_client'
require 'vidispine/api/client/requests'

module Vidispine
  module API
    class Client

      attr_accessor :http_client, :request, :response, :logger

      def initialize(args = { })
        @http_client = HTTPClient.new(args)
        @logger = http_client.logger
      end

      def process_request(request, options = nil)
        @response = nil
        @request = request
        request.client = self unless request.client
        options ||= request.options
        logger.warn { "Request is Missing Required Arguments: #{request.missing_required_arguments.inspect}" } unless request.missing_required_arguments.empty?
        @response = http_client.call_method(request.http_method, { :path => request.path, :query => request.query, :body => request.body }, options)
      end

      def process_request_using_class(request_class, args, options = { })
        @response = nil
        @request = request_class.new(args, options.merge(:client => self))
        process_request(request, options)
      end

      # Exposes HTTP Methods
      # @example http(:get, '/')
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
              { :name => :type, :aliases => [ :object_type ], :default_value => 'item' }, # The documentation states that item is the default, but we get a 'Type is missing error if this is not passed'
              :addItems
            ],
          }.merge(options)
        )
        process_request(_request, options)
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
        process_request(_request, options)
      end
      alias :collection_item_remove :collection_object_remove

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#rename-a-collection
      # @param [Hash] args
      # @option args [String] :collection_id
      def collection_rename(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_method => :put,
            :http_path => 'collection/#{arguments[:collection_id]}/rename',
            :parameters => [
              { :name => :collection_id, :aliases => [ :id ], :send_in => :path },
              { :name => :name, :aliases => [ :collection_name ] },
            ]
          }.merge(options)
        )
        return http(:put, _request.path, '', :query => _request.query_arguments, :headers => { 'Content-Type' => 'text/plain' } )
      end

      # @see http://apidoc.vidispine.com/4.2/ref/collection.html#retrieve-a-list-of-all-collections
      def collections_get(args = { }, options = { })
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
        process_request(_request, options)
      end
      alias :item :item_get

      def item_notifications_delete
        http(:delete, '/item/notification')
      end

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#get--item-(id)-metadata
      def item_metadata_get(args = { }, options = { })
        process_request_using_class(Requests::ItemMetadataGet, args, options)
      end
      alias :item_metadata :item_metadata_get

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/metadata.html#add-a-metadata-change-set
      def item_metadata_set(args = { }, options = { })
        process_request_using_class(Requests::ItemMetadataSet, args, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/item/shape.html#get-files-for-shape
      def item_shape_files_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => '/item/#{path_arguments[:item_id]}/shape/#{path_arguments[:shape_id]}/file',
            :default_parameter_send_in_value => :path,
            :parameters => [
              { :name => :item_id, :required => true },
              { :name => :shape_id, :required => true }
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end
      alias :item_shape_files :item_shape_files_get

      # @see http://apidoc.vidispine.com/4.2.6/ref/item/shape.html#get-shape
      def item_shape_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => '/item/#{path_arguments[:item_id]}/shape/#{path_arguments[:shape_id]}',
            :default_parameter_send_in_value => :path,
            :parameters => [
              { :name => :item_id, :required => true },
              { :name => :shape_id },
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

      # @see http://apidoc.vidispine.com/4.2.6/ref/item/shape.html#get-list-of-shapes
      def item_shapes_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => '/item/#{path_arguments[:item_id]}/shape',
            :default_parameter_send_in_value => :path,
            :parameters => [
              { :name => :item_id, :required => true },
              { :name => :uri, :send_in => :query },
              { :name => :placeholder, :send_in => :query },
              { :name => :tag, :send_in => :query }, # Not Documented
              { :name => :version, :send_in => :matrix }
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

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
        # process_request(_request, options)

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
        process_request(_request, options)
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
        process_request(_request, options)
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
        process_request(_request, options)
      end
      alias :items :items_get

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
        process_request(_request, options)
      end
      alias :item_search :items_search

      # @see http://apidoc.vidispine.com/4.2/ref/job.html#delete--job-(job-id)
      def job_abort(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'job/#{arguments[:job_id]}',
            :http_method => :delete,
            :parameters => [
              { :name => :job_id, :aliases => [ :id ], :send_in => :path },
              :reason
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/job.html#get-job-information
      def job_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'job/#{arguments[:job_id]}',
            :parameters => [
              { :name => :job_id, :aliases => [ :id ], :send_in => :path },
              :metadata
            ]
          }
        )
        process_request(_request, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/job.html#get-list-of-jobs
      def jobs_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'job',
            :parameters => [
              { :name => :jobmetadata, :send_in => :query },
              { :name => :metadata, :send_in => :query },
              { :name => :idOnly, :send_in => :query },
              { :name => 'starttime-from', :send_in => :query },
              { :name => 'starttime-to', :send_in => :qeury },
              { :name => :step, :send_in => :query },

              { :name => :type, :send_in => :matrix },
              { :name => :state, :send_in => :matrix },
              { :name => :first, :send_in => :matrix },
              { :name => :number, :send_in => :matrix },
              { :name => :sort, :send_in => :matrix },
              { :name => :user, :send_in => :matrix }
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end
      alias :jobs :jobs_get

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/field.html#delete--metadata-field-(field-name)
      def metadata_field_delete(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'metadata/#{arguments[:field_name]}',
            :http_method => :delete,
            :parameters => [
              { :name => :field_name, :aliases => [ :name ], :send_in => :path }
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/field.html#get--metadata-field-(field-name)
      def metadata_field_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'metadata/#{arguments[:field_name]}',
            :parameters => [
              { :name => :field_name, :aliases => [ :name ], :send_in => :path }
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

      # @see http://apidoc.vidispine.com/4.2.3/ref/metadata/field-group.html#get-a-list-of-known-groups
      def metadata_field_groups_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'metadata-field/field-group',
            :parameters => [
              :content,
              :traverse,
              :data
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/field.html#retrieve-terse-metadata-schema
      def metadata_field_terse_schema(args = { }, options = { })
        default_options = { :headers => { 'accept' => '*/*' } }
        _options = default_options.merge(options)
        http(:get, 'metadata-field/terse-schema', _options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/metadata/field.html#get--metadata-field
      def metadata_fields_get(args = { }, options = { })
        http(:get, 'metadata-field', options)
      end
      alias :metadata_fields :metadata_fields_get

      # @see http://apidoc.vidispine.com/latest/ref/search.html#id2
      # @example search(:content => :metadata, :field => :title, :item_search_document => { :field => [ { :name => 'title', :value => [ { :value => 'something' } ] } ] } )
      def search(args = { }, options = { })
        process_request_using_class(Requests::Search, args, options)
      end

      def search_browse(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'search',
            :parameters => [
              :content,
              :interval,
              :field,
              :group,
              :language,
              :samplerate,
              :track,
              :terse,
              :include,
              :type,
              :tag,
              :scheme,
              :closedFiles,
              'noauth-url',
              :defaultValue,
              :methodType,
              :version,
              :revision,

              { :name => :first, :send_in => :matrix },

              { :name => :ItemSearchDocument, :send_in => :body }
            ]
          }.merge(options)
        )
        process_request(_request, options)
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
        process_request(_request, options)
      end

      
      def storage_file_copy(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args, 
          {
            :http_path => 'storage/#{path_arguments[:source_storage_id]}/file/#{path_argumetns[:file_id]}/storage/#{path_arguments[:target_source_id]}',
            :http_method => :post,
            :parameters => [
              { :name => :file_id, :send_in => :path, :required => true },
              { :name => :source_storage_id, :send_in => :path, :required => true },
              { :name => :target_storage_id, :send_in => :path, :required => true },
              
              :move,
              :filename,
              :timeDependency,
              :limitRate,
              :notification,
              :notificationData,
              :priority,
              :jobmetadata
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end
      
      # @note UNDOCUMENTED API METHOD
      # @param [Hash] args
      # @option args [String] :storage_id (Required)
      # @option args [String] :path (Required)
      # @option args [Boolean] :create_only
      # @option args [String] :state
      def storage_file_create(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'storage/#{path_arguments[:storage_id]}/file',
            :http_method => :post,
            :parameters => [
              { :name => :storage_id, :send_in => :path, :required => true },

              :createOnly,
              :state,

              { :name => :path, :send_in => :body }
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

      def storage_file_item_get(args = { }, options = { })
        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'storage/#{path_arguments[:storage_id]}/file/#{path_arguments[:file_id]}/item',
            :http_method => :get,
            :parameters => [
              { :name => :storage_id, :send_in => :path, :required => true },
              { :name => :file_id, :send_in => :path, :required => true },

              { :name => :uri, :send_in => :matrix },
              { :name => :path, :send_in => :matrix }
            ]
          }.merge(options)
        )
        process_request(_request, options)
      end

      # Exposes two functions
      #   1. Get status of file in storage
      #     @see http://apidoc.vidispine.com/4.2.3/ref/storage/file.html#get-status-of-file-in-storage
      #
      #   2. Get direct download access to file in storage
      #     @see http://apidoc.vidispine.com/4.2.3/ref/storage/file.html#get-direct-download-access-to-file-in-storage
      def storage_file_get(args = { }, options = { })
        process_request_using_class(Requests::StorageFileGet, args, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/storage/file.html#list-files-in-storage
      def storage_files_get(args = { }, options = { })
        process_request_using_class(Requests::StorageFilesGet, args, options)
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
        process_request(_request, options)
      end
      alias :storage :storage_get

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
        process_request(_request, options)
      end

      # @see http://apidoc.vidispine.com/4.2/ref/storage/storage.html#rescanning
      # @param [String|Hash] args
      # @option args [String] :storage_id
      def storage_rescan(args = { }, options = { })
        storage_id = args.is_a?(String) ? args : begin
          _data = Requests::BaseRequest.process_parameters([ { :name => :storage_id, :aliases => [ :id ] } ], args)
          _args = _data[:arguments_out]
          _args[:storage_id]
        end
        http(:post, "storage/#{storage_id ? "#{storage_id}/" : ''}rescan", '')
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
        process_request(_request, options)
      end
      alias :storages :storages_get

      # @!endgroup API Endpoints
      # ############################################################################################################## #

      # Client
    end

    # API
  end

  # Vidispine
end