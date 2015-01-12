require 'vidispine/api/client'

module Vidispine

  module API

    class Utilities < Client

      attr_accessor :default_metadata_map, :default_storage_map

      def initialize(args = { })
        @default_storage_map = args[:storage_map] || { }
        @default_metadata_map = args[:metadata_map] || { }

        super
      end

      # Converts hash keys to symbols
      #
      # @param [Hash] value hash
      # @param [Boolean] recursive Will recurse into any values that are hashes or arrays
      def symbolize_keys (value, recursive = true)
        case value
          when Hash
            new_val = {}
            value.each { |k,v|
              k = (k.to_sym rescue k)
              v = symbolize_keys(v, true) if recursive and (v.is_a? Hash or v.is_a? Array)
              new_val[k] = v
            }
            return new_val
          when Array
            return value.map { |v| symbolize_keys(v, true) }
          else
            return value
        end
      end # symbolize_keys

      def find_storage_file_path(storage)

      end

      # @param [Hash] :collection
      # @param [String] :collection_id
      # @param [String] :collection_name
      def determine_collection(args, options = { })
        collection = args[:collection] || { }

        # 3 Get Collection
        collection_id = args[:collection_id] || collection['id']
        unless collection_id
          collection_name = args[:collection_name]
          unless collection_name
            file_path_collection_name_position = args[:file_path_collection_name_position]
            raise ArgumentError, ':collection_id, :collection_name, or :file_path_collection_name_position argument is required.' unless file_path_collection_name_position

            file_path = args[:file_path]
            raise ArgumentError, ':file_path is a required argument when using :file_path_collection_name_position' unless file_path

            file_path_split = (file_path.start_with?('/') ? file_path[1..-1] : file_path).split('/')
            collection_name = file_path_split[file_path_collection_name_position]
            raise ArgumentError, 'Unable to determine collection name from path.' unless collection_name
            logger.debug { "Using '#{collection_name}' as collection_name. File Path Array: #{file_path_split.inspect}" }
          end
          # Determine Collection
          #collection = collection_create_if_not_exists(:collection_name => collection_name)
          collection = collection_get_by_name({ :collection_name => collection_name }, options)
        else
          collection ||= collection_get(:collection_id => collection_id)
          raise ArgumentError, 'Collection not found.' unless collection and collection['id']
        end
        collection
      end

      # Adds an Item to a Collection but Gives Multiple ways of Determining the Collection
      # @param [Hash] :item
      # @param [Hash] :collection
      # @param [String] :collection_id
      # @param [String] :collection_name
      # @param [String] :file_path Required if using :file_path_collection_name_position
      # @param [Integer] :file_path_collection_name_position
      def collection_item_add_extended(args = { }, options = { })
        _response = { }

        item = args[:item] || { }
        item_id = args[:item_id] || item['id']

        # # 3 Get Collection
        # collection_id = args[:collection_id] || collection['id']
        # unless collection_id
        #   collection_name = args[:collection_name]
        #   unless collection_name
        #     file_path_collection_name_position = args[:file_path_collection_name_position]
        #     raise ArgumentError, ':collection_id, :collection_name, or :file_path_collection_name_position argument is required.' unless file_path_collection_name_position
        #
        #     file_path_split = (file_path.start_with?('/') ? file_path[1..-1] : file_path).split('/')
        #     collection_name = file_path_split[file_path_collection_name_position]
        #     raise ArgumentError, 'Unable to determine collection name from path.' unless collection_name
        #     logger.debug { "Using '#{collection_name}' as collection_name. File Path Array: #{file_path_split.inspect}" }
        #   end
        #   # Determine Collection
        #   collection = collection_create_if_not_exists(:collection_name => collection_name)
        #   collection_id = collection['id']
        # else
        #   collection ||= collection_get(:collection_id => collection_id)
        #   raise ArgumentError, 'Collection not found.' unless collection
        # end
        collection = determine_collection(args)
        _response[:collection] = collection
        collection_id = collection['id']
        #return

        # 5. Add Item to the Collection
        logger.debug { 'Adding Item to Collection.' }
        collection_object_add_response = collection_object_add(:collection_id => collection_id, :object_id => item_id)
        _response[:collection_object_add] = collection_object_add_response

        _response
      end

      # Transforms metadata from key value to field format
      # { k1 => v1, k2 => v2} becomes [ { :name => k1, :value => [ { :value => v1 } ] }, { :name => k2, :value => [ { :value => v2 } ] } ]
      def transform_metadata_to_fields(metadata_in, options = { })
        _metadata_map = default_metadata_map.merge(options[:metadata_map] || { })
        metadata_in.map { |k,v| { :name => (_metadata_map[k] || k), :value => [ { :value => v } ] } }
      end

      # Add an item to the system using file path metadata field as the key
      # 1. Search for pre existing asset
      # 2. Create a placeholder with metadata (if asset doesn't exist)
      # 3. Create an original shape.
      # 4. Poll the Job status of the shape creation
      # 5. Trigger the Transcode of the Proxy, thumbnails
      # 6. Trigger the Transcode of the thumbnail.
      # 7. Trigger the Transcode of the poster frame
      def item_add_using_file_path_metadata(args = { }, options = { })
        args = symbolize_keys(args, false)
        _response = { }

        # 1. Receive a File Path
        file_path = args[:file_path]
        raise ArgumentError, ':file_path is a required argument.' unless file_path

        metadata_file_path_field_id = args[:metadata_file_path_field_id]
        raise ArgumentError, ':metadata_file_path_field_id is a required argument.' unless metadata_file_path_field_id

        # 2. Determine Storage ID
        storage_path_map = args[:storage_path_map]
        raise ArgumentError, ':storage_path_map is a required argument.' unless storage_path_map

        # Make sure the keys are strings
        storage_path_map = Hash[storage_path_map.map { |k,v| [k.to_s, v] }] if storage_path_map.is_a?(Hash)

        volume_path, storage = storage_path_map.find { |path, _| file_path.start_with?(path) }
        raise "Unable to find match in storage path map for '#{file_path}'. Storage Map: #{storage_path_map.inspect}" unless volume_path

        file_path_relative_to_storage_path = file_path.sub(volume_path, '')
        logger.debug { "File Path Relative to Storage Path: #{file_path_relative_to_storage_path}" }

        storage = storage_get(:id => storage) if storage.is_a?(String)
        _response[:storage] = storage
        raise 'Error Retrieving Storage Record. Storage Id: #{' unless storage

        storage_id = storage['id']
        storage_uri_raw = storage['method'].first['uri']
        storage_uri = URI.parse(storage_uri_raw)

        vidispine_file_path = File.join(storage_uri.path, file_path_relative_to_storage_path)
        logger.debug { "Vidispine File Path: '#{vidispine_file_path}'" }
        _response[:vidispine_file_path] = vidispine_file_path

        _metadata = args[:metadata] || { }
        _metadata[metadata_file_path_field_id] ||= vidispine_file_path

        # map metadata assuming 1 value per field
        _metadata_as_fields = transform_metadata_to_fields(_metadata, args)

        # 4.1 Search for Item using File Path
        search_response = search(:content => 'metadata', :item_search_document => { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ] } ) || { 'entry' => [ ] }
        _response[:search] = search_response

        item = (search_response['entry'].first || { })['item']
        unless item
          # If the item wasn't found then get the file id for the file
          # 4.1 Search for the storage file record
          storage_file_get_response = storage_file_get(:storage_id => storage_id, :path => file_path_relative_to_storage_path) || { 'file' => [ ] }
          raise "Error Getting Storage File. '#{response.inspect}'" unless storage_file_get_response and storage_file_get_response['id']
          file = storage_file_get_response['file'].first
          _response[:storage_file_get_response] = storage_file_get_response

          unless file
            # 4.1.1 Create the storage file record if it does not exist
            file = storage_file_create_response = storage_file_create(:storage_id => storage_id, :path => file_path_relative_to_storage_path, :state => 'CLOSED')
            raise "Error Creating File on Storage. Response: #{response}" unless file
            _response[:storage_file_create_response] = storage_file_create_response
          end

          # 4.2 Create a Placeholder
          logger.debug { 'Creating Placeholder.' }
          #placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :group => [ 'Film' ], :timespan => [ { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ], :start => '-INF', :end => '+INF' } ] } }
          placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :group => [ 'Film' ], :timespan => [ { :field => _metadata_as_fields, :start => '-INF', :end => '+INF' } ] } }
          item = placeholder = import_placeholder(placeholder_args)
          _response[:placeholder] = placeholder
        end
        _response[:item] = item
        item_id = item['id']

        if options[:add_item_to_collection]
          logger.debug { 'Determining Collection to Add the Item to.' }
          collection = determine_collection(args, options)
          _response[:collection] = collection
          collection_id = collection['id']

          logger.debug { 'Adding Item to Collection.' }
          collection_object_add_response = collection_object_add(:collection_id => collection_id, :object_id => item_id)
          _response[:collection_object_add] = collection_object_add_response
        end

        # Item was already in the system so exit here
        return _response unless file

        file_id = file['id']
        raise "File Id Not Found. #{file.inspect}" unless file_id

        # 6. Add the file as the original shape
        logger.debug { 'Adding the file as the Original Shape.' }
        item_shape_import_response = item_shape_import(:item_id => item_id, :file_id => file_id, :tag => 'original')
        _response[:item_shape_import] = item_shape_import_response

        job_id = item_shape_import_response['jobId']
        job_monitor_response = wait_for_job_completion(:job_id => job_id) { |env|
          logger.debug { "Waiting for Item Shape Import Job to Complete. Time Elapsed: #{Time.now - env[:time_started]} seconds" }
        }
        last_response = job_monitor_response[:last_response]
        raise "Error Adding file As Original Shape. Response: #{last_response.inspect}" unless last_response['status'] == 'FINISHED'

        # 7. Generate the Transcode of the item
        transcode_tag = args[:transcode_tag] || 'lowres'
        logger.debug { 'Generating Transcode of the Item.' }
        item_transcode_response = item_transcode(:item_id => item_id, :tag => transcode_tag)
        _response[:item_transcode] = item_transcode_response

        # 8. Generate the Thumbnails and Poster Frame
        create_thumbnails = args.fetch(:create_thumbnails, true)
        create_posters = args[:create_posters] || 3
        logger.debug { 'Generating Thumbnails(s) and Poster Frame.' }
        item_thumbnail_response = item_thumbnail(:item_id => item_id, :createThumbnails => create_thumbnails, :createPosters => create_posters)
        _response[:item_thumbnail] = item_thumbnail_response

        _response
      end

      # @param [Hash] args
      # @option args [String] :file_path (Required)
      # @option args [String] :metadata_file_path_field_id (Required)
      # @option args [Hash] :storage_path_map (Required)
      # @option args [String] :collection_id Required if :collection_name or :file_path_collection_name_position is not set
      # @option args [String] :collection_name Required if :collection_id or :file_path_collection_name_position is not set
      # @option args [Integer] :file_path_collection_name_position Required if :collection_id or :collection_name is not set
      # @option args [Hash] :placeholder_args ({ :container => 1, :video => 1 })
      def collection_file_add_using_path(args = { }, options = { })
        args = symbolize_keys(args, false)
        _response = { }

        # 1. Receive a File Path
        file_path = args[:file_path]
        raise ArgumentError, ':file_path is a required argument.' unless file_path

        metadata_file_path_field_id = args[:metadata_file_path_field_id]
        raise ArgumentError, ':metadata_file_path_field_id is a required argument.' unless metadata_file_path_field_id

        # 2. Determine Storage ID
        storage_path_map = args[:storage_path_map]
        raise ArgumentError, ':storage_path_map is a required argument.' unless storage_path_map

        # Make sure the keys are strings
        storage_path_map = Hash[storage_path_map.map { |k,v| [k.to_s, v] }] if storage_path_map.is_a?(Hash)

        volume_path, storage = storage_path_map.find { |path, _| file_path.start_with?(path) }
        raise "Unable to find match in storage path map for '#{file_path}'. Storage Map: #{storage_path_map.inspect}" unless volume_path

        file_path_relative_to_storage_path = file_path.sub(volume_path, '')
        logger.debug { "File Path Relative to Storage Path: #{file_path_relative_to_storage_path}" }

        storage = storage_get(:id => storage) if storage.is_a?(String)
        _response[:storage] = storage
        raise 'Error Retrieving Storage Record. Storage Id: #{' unless storage

        storage_id = storage['id']
        storage_uri_raw = storage['method'].first['uri']
        storage_uri = URI.parse(storage_uri_raw)

        vidispine_file_path = File.join(storage_uri.path, file_path_relative_to_storage_path)
        logger.debug { "Vidispine File Path: '#{vidispine_file_path}'" }
        _response[:vidispine_file_path] = vidispine_file_path

        # 3 Get Collection
        collection_id = args[:collection_id]
        unless collection_id
          collection_name = args[:collection_name]
          unless collection_name
            file_path_collection_name_position = args[:file_path_collection_name_position]
            raise ArgumentError, ':collection_id, :collection_name, or :file_path_collection_name_position argument is required.' unless file_path_collection_name_position

            file_path_split = (file_path_relative_to_storage_path.start_with?('/') ? file_path_relative_to_storage_path[1..-1] : file_path_relative_to_storage_path).split('/')
            collection_name = file_path_split[file_path_collection_name_position]
            raise ArgumentError, 'Unable to determine collection name from path.' unless collection_name
            logger.debug { "Using '#{collection_name}' as collection_name. File Path Array: #{file_path_split.inspect}" }
          end
          # Determine Collection
          collection = collection_create_if_not_exists(:collection_name => collection_name)
          collection_id = collection['id']
        else
          collection = collection_get(:collection_id => collection_id)
          raise ArgumentError, 'Collection not found.' unless collection
        end
        _response[:collection] = collection
        #return

        # 4.1 Search for Item using File Path
        search_response = search(:content => 'metadata', :item_search_document => { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ] } ) || { 'entry' => [ ] }
        _response[:search] = search_response

        item = (search_response['entry'].first || { })['item']
        unless item
          # If the item wasn't found then get the file id for the file
          # 4.1 Search for the storage file record
          storage_file_get_response = storage_file_get(:storage_id => storage_id, :path => file_path_relative_to_storage_path) || { 'file' => [ ] }
          raise "Error Getting Storage File. '#{response.inspect}'" unless response
          file = storage_file_get_response['file'].first
          _response[:storage_file_get_response] = storage_file_get_response

          unless file
            # 4.1.1 Create the storage file record if it does not exist
            file = storage_file_create_response = storage_file_create(:storage_id => storage_id, :path => file_path_relative_to_storage_path, :state => 'CLOSED')
            raise "Error Creating File on Storage. Response: #{response}" unless file
            _response[:storage_file_create_response] = storage_file_create_response
          end

          # 4.2 Create a Placeholder
          logger.debug { 'Creating Placeholder.' }
          placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :group => [ 'Film' ], :timespan => [ { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ], :start => '-INF', :end => '+INF' } ] } }
          item = placeholder = import_placeholder(placeholder_args)
          _response[:placeholder] = placeholder
        # else
        #   logger.debug { 'Getting File Using Path.' }
        #   response = storage_file_get(:storage_id => storage_id, :path => file_path_relative_to_storage_path) || { 'file' => [ ] }
        #   raise "Error Getting Storage File. '#{response.inspect}'" unless response
        #
        #   file = response['file'].first
        end

        _response[:item] = item
        item_id = item['id']

        # 5. Add Item to the Collection
        logger.debug { 'Adding Item to Collection.' }
        collection_object_add_response = collection_object_add(:collection_id => collection_id, :object_id => item_id)
        _response[:collection_object_add] = collection_object_add_response

        # Item was already in the system so exit here
        return _response unless file

        file_id = file['id']
        raise "File Id Not Found. #{file.inspect}" unless file_id

        # 6. Add the file as the original shape
        logger.debug { 'Adding the file as the Original Shape.' }
        item_shape_import_response = item_shape_import(:item_id => item_id, :file_id => file_id, :tag => 'original')
        _response[:item_shape_import] = item_shape_import_response

        job_id = item_shape_import_response['jobId']
        job_monitor_response = wait_for_job_completion(:job_id => job_id) { |env|
          logger.debug { "Waiting for Item Shape Import Job to Complete. Time Elapsed: #{Time.now - env[:time_started]} seconds" }
        }
        last_response = job_monitor_response[:last_response]
        raise "Error Adding file As Original Shape. Response: #{last_response.inspect}" unless last_response['status'] == 'FINISHED'

        # 7. Generate the Transcode of the item
        transcode_tag = args[:transcode_tag] || 'lowres'
        logger.debug { 'Generating Transcode of the Item.' }
        item_transcode_response = item_transcode(:item_id => item_id, :tag => transcode_tag)
        _response[:item_transcode] = item_transcode_response

        # 8. Generate the Thumbnails and Poster Frame
        create_thumbnails = args.fetch(:create_thumbnails, true)
        create_posters = args[:create_posters] || 3
        logger.debug { 'Generating Thumbnails(s) and Poster Frame.' }
        item_thumbnail_response = item_thumbnail(:item_id => item_id, :createThumbnails => create_thumbnails, :createPosters => create_posters)
        _response[:item_thumbnail] = item_thumbnail_response

        _response
      end

      # Searches for a collection by name and if a match is not found then a new collection is created
      # This method will only return the first match if an existing collection is found.
      def collection_create_if_not_exists(args = { }, options = { })
        return args.map { |v| collection_create_if_not_exists(v, options) } if args.is_a?(Array)
        args = args.is_a?(Hash) ? args : { :collection_name => args }

        collection_name = args[:collection_name]
        raise ArgumentError, 'collection_name is required.' unless collection_name
        case_sensitive = options.fetch(:case_sensitive, true)

        collection = collection_get_by_name( :collection_name => collection_name, :case_sensitive => case_sensitive )
        collection_already_existed = collection ? true : false
        collection ||= collection_create(collection_name)
        options[:extended_response] ?
            { :collection => collection, :collection_already_existed => collection_already_existed } :
            collection
      end

      # Searches for a collection by name
      # @param [Hash] args
      # @option args [String] :collection_name
      # @option args [Boolean] :return_first_match (true)
      # @option args [Boolean] :case_sensitive (true)
      def collection_get_by_name(args = { }, options = { })
        return collection_create_if_not_exists(args, options) if options[:collection_create_if_not_exists]
        args = args.is_a?(Hash) ? args : { :collection_name => args }

        collection_name = args[:collection_name] || args[:name]
        return_first_match = options.fetch(:return_first_match, true)

        unless collection_name
          raise ArgumentError, 'collection_name is required.'
        end

        collections = ( (collections_get || { })['collection'] || [ ] )

        comparison_method, comparison_value = options.fetch(:case_sensitive, true) ? [ :eql?, true ] : [ :casecmp, 0 ]
        collections_search_method = return_first_match ? :find : :select
        collections.send(collections_search_method) { |c| c['name'].send(comparison_method, collection_name) == comparison_value }
      end

      # SEQUENCE THAT CREATE AN ITEM AND THE PROXY USING THE FILE ID
      def item_create_with_proxy_using_storage_file_paths(args = { }, options = { })

        original_file_path = args[:original_file_path] || args[:original]
        lowres_file_path = args[:lowres_file_path] || args[:lowres]

        placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1 }

        storage_id = args[:storage_id]

        create_posters = args[:create_posters] #|| '300@NTSC'
        create_thumbnails = args.fetch(:create_thumbnails, true)

        # Create a placeholder
        # /API/import/placeholder/?container=1&video=1
        place_holder = placeholder_create(placeholder_args)
        item_id = place_holder['id']

        # /API/storage/VX-2/file/?path=storages/test/test_orginal2.mp4
        _original_file = original_file = storage_file_get(:storage_id => storage_id, :path => original_file_path)
        raise "Unexpected Response Format. Expecting Hash instead of #{original_file.class.name} #{original_file}" unless _original_file.is_a?(Hash)

        original_file = original_file['file']
        begin
          original_file = original_file.first
        rescue => e
          raise "Error Getting File from Response. #{$!}\n#{original_file.inspect}\n#{_original_file.inspect}"
        end
        raise RuntimeError, "File Not Found. '#{original_file_path}' in storage '#{storage_id}'" unless original_file
        original_file_id = original_file['id']

        # /API/item/VX-98/shape?tag=original&fileId=[FileIDofOriginal]
        item_shape_import(:item_id => item_id, :tag => 'original', :file_id => original_file_id)

        # /API/storage/VX-2/file/?path=storages/test/test_proxy2.mp4
        lowres_file = storage_file_get(:storage_id => storage_id, :path => lowres_file_path)
        lowres_file_id = lowres_file['file'].first['id']

        # /API/item/VX-98/shape?tag=lowres&fileId=[FileIDofProxy]
        item_shape_import(:item_id => item_id, :tag => 'lowres', :file_id => lowres_file_id)

        # /API/item/VX-98/thumbnail/?createThumbnails=true&createPoster
        item_thumbnail_args = { :item_id => item_id }
        item_thumbnail_args[:createThumbnails] = create_thumbnails
        item_thumbnail_args[:createPosters] = create_posters if create_posters
        item_thumbnail(item_thumbnail_args)

        { :item_id => item_id, :original_file_id => original_file_id, :lowres_file_id => lowres_file_id }
      end

      # SEQUENCE THAT CREATE AN ITEM AND THE PROXY USING THE FILE URI/PATH
      def item_create_with_proxy_using_file_uri(args = { }, options = { })
        original_file_uri = args[:original_file_uri] || args[:original]
        file_type = args[:file_type] || 'video'

        import_tag = args[:import_tag] || 'lowres'

        placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1 }

        storage_id = args[:storage_id]

        # /API/import/placeholder/?container=1&video=1
        placeholder = import_placeholder(placeholder_args)
        placeholder_item_id = placeholder['id']

        # /API/import/placeholder/VX-99/video/?uri=file%3A%2F%2F%2Fsrv%2Fmedia1%2Ftest_orginal2.mp4&tag=lowres
        item = import_placeholder_item(:item_id => placeholder_item_id, :type => file_type, :uri => original_file_uri, :tag => import_tag)
        item_id = item['file'].first['id']

        # /API/item/VX-99/shape?tag=lowres&fileId=VX-136
        #item_shape_import(:item_id => item_id, :tag => nil, :file_id => nil)

        # /API/storage/VX-2/file/?path=storages/test/test_orginal2.mp4
        #storage_file_get(:storage_id => storage_id)
      end

      # @note THIS IS A CANTEMO SPECIFIC CALL
      def item_annotation_create(args = { }, options = { })
        # _args = args
        # item_id = _args[:item_id]
        #
        # in_point = _args[:in_point]
        # out_point = _args[:out_point]
        # title = _args[:title]
        #
        # body = { }
        # body[:title] = title if title
        # body[:inpoint] = in_point if in_point
        # body[:outpoint] = out_point if out_point
        #
        # http(:post, "v1/item/#{item_id}/annotation", :body => body)

        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'v1/item/#{arguments[:item_id]}/annotation',
            :http_method => :post,
            :default_parameter_send_in_value => :body,
            :parameters => [
              { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path },

              :inpoint,
              :outpoint,
              { :name => :title, :default => '' },
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      # @note THIS IS A CANTEMO SPECIFIC CALL
      def item_annotation_get(args = { }, options = { })
        args = { :item_id => args } if args.is_a?(String)
        # item_id = args[:item_id]
        # http(:get, "v1/item/#{item_id}/annotation")

        _request = Requests::BaseRequest.new(
          args,
          {
            :http_path => 'v1/item/#{arguments[:item_id]}/annotation',
            :parameters => [
              { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path }
            ]
          }.merge(options)
        )
        process_request(_request)
      end

      def storage_file_copy_extended(args = { }, options = { })
        _args = symbolize_keys(args, false)
        _data = Requests::BaseRequest.process_parameters([ { :name => :use_source_filename }, { :name => :file_id }, { :name => :filename }, { :name => :source_storage_id } ], _args)
        _args = _args.merge(_data[:arguments_out])

        # Get the source file name and set it as the destination file name
        if options[:use_source_filename]
          file_id = _args[:file_id]
          source_storage_id = _args[:source_storage_id]
          file = storage_file_get(:storage_id => source_storage_id, :file_id => file_id)
          args[:filename] = file[:filename]
        end

        storage_file_copy(args, options)
      end

      def storage_file_create_extended(args = { }, options = { })
        _args = symbolize_keys(args, false)
        _params = Requests::StorageFileCreate::PARAMETERS.concat [ { :name => :dir, :aliases => [ :directory ], :send_in => :none }, { :name => :storage_map, :send_in => :none } ]
        _data = Requests::BaseRequest.process_parameters(_params, _args)
        _args = _args.merge(_data[:arguments_out])

        storage_path_map = _args.delete(:storage_map) { }
        storage_path_map = Hash[storage_path_map.map { |k,v| [k.to_s, v] }] if storage_path_map.is_a?(Hash)

        dir = _args.delete(:dir) { }
        if dir
          raise ArgumentError, ':storage_map is a required argument.' unless storage_path_map

          volume_path, storage = storage_path_map.find { |path, _| dir.start_with?(path) }
          raise "Unable to find match in storage path map for '#{dir}'. Storage Map: #{storage_path_map.inspect}" unless volume_path

          dir_path_relative_to_storage = dir.sub(volume_path, '')

          storage = storage_get(:id => storage) if storage.is_a?(String)
          raise 'Error Retrieving Storage Record. Storage Id: #{' unless storage

          # storage_id = storage['id']
          storage_uri_raw = storage['method'].first['uri']
          storage_uri = URI.parse(storage_uri_raw)

          vidispine_dir_path = File.join(storage_uri.path, dir_path_relative_to_storage)
          logger.debug { "Vidispine Dir Path: '#{vidispine_dir_path}'" }


          glob_path = dir.end_with?('*') ? vidispine_dir_path : File.join(vidispine_dir_path, '*')
          paths = Dir.glob(glob_path)

          return paths.map do |local_absolute_path|
            logger.debug { "Found Path: '#{local_absolute_path}'" }
            _path = local_absolute_path
            file_path_relative_to_storage_path = _path.sub(volume_path, '')
            logger.debug { "File Path Relative to Storage Path: #{file_path_relative_to_storage_path}" }

            _args[:path] = file_path_relative_to_storage_path
            storage_file_create(_args, options)
          end
        end

        storage_file_create(_args, options)
      end

      # @param [Hash] args
      # @option args [String] :job_id (Required)
      # @option args [Integer] :delay (15)
      # @option args [Integer] :timeout The timeout in seconds
      def wait_for_job_completion(args = { })
        job_id = args[:job_id]
        raise ArgumentError, 'job_id is a required argument.' unless job_id
        delay = args[:delay] || 15

        timeout = args[:timeout]
        time_started = Time.now

        _response = { }
        continue_monitoring = true
        timed_out = false
        loop do
          _response = job_get(:job_id => job_id)
          break unless _response

          job_status = _response['status']
          break if %w(FINISHED FINISHED_WARNING FINISHED_TOTAL ABORTED).include?(job_status)

          break if timeout and (timed_out = ((Time.now - time_started) > timeout))

          if block_given?
            yield_out = {
              :time_started => time_started,
              :latest_response => _response,
              :job_status => job_status,
              :continue_monitoring => continue_monitoring,
              :delay => delay
            }
            yield yield_out
            break unless continue_monitoring
          else
            logger.debug { "Waiting for job completion. Job: #{job_status}" }
          end

          sleep(delay)
        end

        { :last_response => _response, :time_started => time_started, :timed_out => timed_out }
      end

      # Utilities
    end

    # API
  end

  # Vidispine
end