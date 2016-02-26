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

      # Tries to find a collection using either the collection id, name, or a file path with a collection name position.
      # For use in other methods that need to perform the same type of lookup
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
        args = symbolize_keys(args, false)

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

        # 5. Add Item to the Collection
        logger.debug { 'Adding Item to Collection.' }
        collection_object_add_response = collection_object_add(:collection_id => collection_id, :object_id => item_id)
        _response[:collection_object_add] = collection_object_add_response

        _response
      end

      # # Transforms metadata from key value to field format
      # # { k1 => v1, k2 => v2} becomes [ { :name => k1, :value => [ { :value => v1 } ] }, { :name => k2, :value => [ { :value => v2 } ] } ]
      # def transform_metadata_to_fields(metadata_in, options = { })
      #   _metadata_map = default_metadata_map.merge(options[:metadata_map] || { })
      #   metadata_in.map { |k,v| { :name => (_metadata_map[k] || k), :value => [ { :value => v } ] } }
      # end

      # Transforms metadata from key value to MetadataDocument field and group sequences
      # { k1 => v1, k2 => v2 } becomes
      #   {
      #     :field => [
      #       { :name => map[k1][:field], :value => [ { :value => v1 } ] },
      #       { :name => map[k2][:field], :value => [ { :value => v2 } ] }
      #     ],
      #     :group => [ ]
      #   }
      #
      # Metadata Map Example
      # metadata_map = {
      #   'Campaign Title' => { :group => 'Film', :field => 'portal_mf409876' },
      #   'Client' => { :group => 'Editorial and Film', :field => 'portal_mf982459' },
      #   'Product' => { :group => 'Film', :field => 'portal_mf264604' },
      #   'Studio Tracking ID' => { :group => 'Film', :field => 'portal_mf846239' },
      #   #'File Path' => { :field => 'portal_mf48881', :group => 'Film' }
      #   #'File Path' => { :field => 'portal_mf48881' }
      #   'File Path' => 'portal_mf48881'
      # }
      #
      # @see http://apidoc.vidispine.com/4.2.3/ref/xml-schema.html#schema-element-MetadataDocument
      #
      # @param [Hash] metadata_in Key value pair where the key is an alias for a vidispine metadata field name
      # @param [Hash] map A mapping of metadata field name aliases to proper metadata field name and optionally
      # metadata group name { 'Some Field' => { :field => 'properFieldName', :group => 'groupName' } }
      # @param [Hash] options
      # @option options [Hash] :default_metadata_map (default_metadata_map)
      # @option options [Hash] :metadata_map
      def transform_metadata_to_fields(metadata_in, map = { }, options = { })
        map = (options[:default_metadata_map] || default_metadata_map).merge(map.merge(options[:metadata_map] || { }))
        groups = { }
        metadata_in.each do |k,v|
          _map = map[k]
          next unless _map
          [*_map].each do |_map_|
            _map_ = { :field => _map_ } if _map_.is_a?(String)
            (groups[_map_[:group]] ||= { })[_map_[:field]] = v
          end
        end

        _field = groups.delete(nil) { { } }.map { |fname, values| { :name => fname, :value => [*values].map { |v| { :value => v } } } }
        _group = groups.map { |name, fields| { :name => name, :field => fields.map { |fname, values| { :name => fname, :value => [*values].map { |v| { :value => v } } } } } }

        # metadata_out = { }
        # metadata_out[:field] = _field unless _field.empty?
        # metadata_out[:group] = _group unless _group.empty?
        # metadata_out
        { :field => _field, :group => _group }
      end

      # {
      #   "item": [
      #     {
      #       "metadata": {
      #         "revision": "VX-348,VX-766,VX-350,VX-352,VX-767,VX-353,VX-816,VX-815,VX-346",
      #         "group": [
      #           "Film"
      #         ],
      #         "timespan": [
      #           {
      #             "start": "-INF",
      #             "end": "+INF",
      #             "field": [
      #               {
      #                 "name": "portal_mf778031",
      #                 "uuid": "4150479f-b15e-475b-bc48-80ef85d3c2cf",
      #                 "change": "VX-767",
      #                 "user": "admin",
      #                 "value": [
      #                   {
      #                     "uuid": "a7f91e7c-ffc6-4ba1-9658-3458bec886e9",
      #                     "change": "VX-767",
      #                     "user": "admin",
      #                     "value": "556dd36a02a760d6bd000071",
      #                     "timestamp": "2015-07-06T22:25:17.926+0000"
      #                   }
      #                 ],
      #                 "timestamp": "2015-07-06T22:25:17.926+0000"
      #               },
      #               {
      #                 "name": "portal_mf268857"
      #               },
      #               {
      #                 "name": "portal_mf196812"
      #               },
      #               {
      #                 "name": "portal_mf201890"
      #               },
      #               {
      #                 "name": "portal_mf619153"
      #               },
      #               {
      #                 "name": "portal_mf551902"
      #               },
      #               {
      #                 "name": "portal_mf48881"
      #               },
      #               {
      #                 "name": "portal_mf257027"
      #               },
      #               {
      #                 "name": "portal_mf897662"
      #               },
      #               {
      #                 "name": "portal_mf396149"
      #               }
      #             ],
      #             "group": [
      #
      #             ]
      #           }
      #         ]
      #       },
      #       "id": "VX-84"
      #     }
      #   ]
      # }
      def self.transform_metadata_get_response_to_hash(_response, options = { })
        items = _response['item'] || _response
        item = items.first
        item_metadata = item['metadata']
        metadata = { }

        # group = item_metadata['group'].first
        timespans = item_metadata['timespan']
        timespans.each do |t|
          metadata.merge!(transform_metadata_group(t))
        end
        metadata
      end

      def transform_metadata_get_response_to_hash(_response, options = { })
        self.class.transform_metadata_get_response_to_hash(_response, options)
      end

      def self.transform_metadata_group(group, breadcrumbs = [ ])
        metadata = { }
        name = group['name']

        _breadcrumbs = breadcrumbs.dup << name
        bc = _breadcrumbs.compact.join(':')
        bc << ':' unless bc.empty?

        groups = group['group']
        if groups.length == 1 and (_group_name = groups.first).is_a?(String)
          # group_name = _group_name.is_a?(String) ? _group_name : ''
        else
          # group_name = ''
          groups.each do |g|
            metadata.merge!(transform_metadata_group(g, _breadcrumbs))
          end
        end

        fields = group['field']
        fields.each do |f|
          # field_name = "#{group_name}#{group_name.empty? ? '' : ':'}#{f['name']}"
          field_name = "#{bc}#{f['name']}"
          field_value_raw = f['value']
          if field_value_raw.is_a?(Array)
            field_value = field_value_raw.map { |v| v['value'] }
            field_value = field_value.first if field_value.length == 1
          else
            field_value = field_value_raw
          end
          metadata[field_name] = field_value
        end
        metadata
      end

      def build_item_search_document(criteria, options = { })
        fields = criteria[:fields] || criteria
        item_search_document = {
            :field => fields.map { |fname, values|
              if values.is_a?(Hash)
                #_values = values.map { |k, values| { k => [ { :value => [*values].map { |v| { :value => v } } } ] } }.inject({}) { |hash, value| hash.merge(value) }
                _values = Hash[ values.map { |k, values| [ k, [ { :value => [*values].map { |v| { :value => v } } } ] ] } ]
              else
                _values = { :value => [*values].map { |v| { :value => v } } }
              end
              { :name => fname }.merge(_values)
            }
        }
        item_search_document
      end

      # @return [Hash]
      def build_metadata_document(metadata_in, map = { }, options = { })
        map = (options[:default_metadata_map] || default_metadata_map).merge((options[:metadata_map] || { }).merge(map))
        groups = { }
        metadata_in.each do |k,v|
          _map = map[k]
          next unless _map
          _map = [ _map ] unless _map.is_a?(Array)
          _map.each do |_map_|
            _map_ = { :field => _map_ } if _map_.is_a?(String)
            #puts "##{_map_[:group].inspect} #{_map_.class.name} #{_map_.inspect}"
            (groups[_map_[:group]] ||= { })[_map_[:field]] = v
          end
        end

        _field = groups.delete(nil) { { } }.map { |fname, values| { :name => fname, :value => [*values].map { |v| { :value => v } } } }
        _group = groups.map { |name, fields| { :name => name, :field => fields.map { |fname, values| { :name => fname, :value => [*values].map { |v| { :value => v } } } } } }

        # metadata_out = { }
        # metadata_out[:field] = _field unless _field.empty?
        # metadata_out[:group] = _group unless _group.empty?
        # metadata_out

        if (!_field.empty? && !_group.empty?) || _group.length > 1
          logger.warn { 'Multiple metadata groups were specified but only one group will be ingested by Vidispine.' }
        end

        #{ :field => _field, :group => _group }
        if _field.empty? && _group.length == 1
          _group = _group.first
          group_name = _group[:name]
          group_fields = _group[:field]
          return { :group => [ group_name ], :timespan => [ { :start => '-INF', :end => '+INF', :field => group_fields } ] }
        end

        { :timespan => [ { :start => '-INF', :end => '+INF', :field => _field, :group => _group } ] }
      end

      # @return [Array]
      def build_metadata_documents(metadata_in, map = { }, options = { })
        map = (options[:default_metadata_map] || default_metadata_map).merge(map.merge(options[:metadata_map] || { }))
        groups = { }
        metadata_in.each do |k,v|
          _map = map[k]
          next unless _map
          _map = [ _map ] unless _map.is_a?(Array)
          _map.each do |_map_|
            _map_ = { :field => _map_ } if _map_.is_a?(String)
            #puts "##{_map_[:group].inspect} #{_map_.class.name} #{_map_.inspect}"
            (groups[_map_[:group]] ||= { })[_map_[:field]] = v
          end
        end

        _field = groups.delete(nil) { { } }.map { |fname, values| { :name => fname, :value => [*values].map { |v| { :value => v } } } }
        _groups = groups.map { |name, fields| { :name => name, :field => fields.map { |fname, values| { :name => fname, :value => [*values].map { |v| { :value => v } } } } } }

        docs = [ ]

        if !_field.empty?
          docs << { :timespan => [ { :start => '-INF', :end => '+INF', :field => _field, :group => [ ] } ] }
        end

        _groups.each do |_group|
          group_name = _group[:name]
          group_fields = _group[:field]
          docs << { :group => [ group_name ], :timespan => [ { :start => '-INF', :end => '+INF', :field => group_fields } ] }
        end

        docs
      end


      # Adds a file using the files path

      # @param [Hash] args
      # @option args [String] :file_path
      # @option args [Hash|null] :storage_path_map
      # @option args [String] :storage_method_type ('file')
      # @option args [Hash] :metadata ({})
      # @option args [Hash] :metadata_map ({})
      # @option args [Hash] :file
      # @option args [Boolean] :create_thumbnails (false)
      # @option args [Integer|false] :create_posters (3)

      # @param [Hash] options
      # @option options [Boolean] :add_item_to_collection
      # @option options [Boolean] :wait_for_transcode_job (false)
      # @option options [Boolean] :skip_transcode_if_shape_with_tag_exists (true)
      #
      # @return [Hash]
      def item_add_using_file_path(args = { }, options = { })
        args = symbolize_keys(args, false)
        _response = { }

        # 1. Receive a File Path
        file_path = args[:file_path]
        raise ArgumentError, ':file_path is a required argument.' unless file_path

        # 2. Determine Storage ID
        storage_path_map = args[:storage_path_map]
        storage_path_map = storage_file_path_map_create unless storage_path_map and !storage_path_map.empty?

        volume_path, storage = storage_path_map.find { |path, _| file_path.start_with?(path) }
        raise "Unable to find match in storage path map for '#{file_path}'. Storage Map: #{storage_path_map.inspect}" unless volume_path

        file_path_relative_to_storage_path = file_path.sub(volume_path, '')
        logger.debug { "File Path Relative to Storage Path: #{file_path_relative_to_storage_path}" }

        storage = storage_get(:id => storage) if storage.is_a?(String)
        _response[:storage] = storage
        storage_id = storage['id']
        raise "Error Retrieving Storage Record. Storage: #{storage.inspect}" unless storage_id

        # The method type of the URI to lookup
        storage_method_type = args[:storage_method_type] ||= 'file'

        storage_uri_method = "#{storage_method_type}:"
        storage_uri_raw = (storage['method'].find { |v| v['uri'].start_with?(storage_uri_method) } || { })['uri'] rescue nil
        raise "Error Getting URI from Storage Method. Storage: #{storage.inspect}" unless storage_uri_raw
        storage_uri = URI.parse(storage_uri_raw)

        vidispine_file_path = File.join(storage_uri.path, file_path_relative_to_storage_path)
        logger.debug { "Vidispine File Path: '#{vidispine_file_path}'" }
        _response[:vidispine_file_path] = vidispine_file_path

        _metadata = args[:metadata] || { }
        _metadata_map = args[:metadata_map] || { }

        # map metadata assuming 1 value per field
        #_metadata_as_fields = transform_metadata_to_fields(_metadata, _metadata_map, options)
        #metadata_document = build_metadata_document(_metadata, _metadata_map, options)
        metadata_documents = build_metadata_documents(_metadata, _metadata_map, options)
        metadata_document = metadata_documents.shift || { }


        # Allow the file to be passed in
        file = args[:file]
        if file and !file['item']
          # If the passed file doesn't have an item then requery to verify that the item is absent
          storage_file_get_response = storage_file_get(:storage_id => storage_id, :file_id => file['id'], :include_item => true)
          raise "Error Getting Storage File. '#{storage_file_get_response.inspect}'" unless storage_file_get_response and storage_file_get_response['id']
          _response[:storage_file_get_response] = storage_file_get_response

          file = storage_file_get_response
        else
          storage_file_get_or_create_response = storage_file_get_or_create(storage_id, file_path_relative_to_storage_path, :extended_response => true)
          _response[:storage_file_get_or_create_response] = storage_file_get_or_create_response
          file = storage_file_get_or_create_response[:file]
          file_found = storage_file_get_or_create_response[:file_already_existed]
        end

        if file
          _response[:item] = item = file['item']
          file_found = true
        end

        _response[:file_already_existed] = file_found
        _response[:item_already_existed] = !!item
        return _response if item

        file_id = file['id']

        unless item
          # 4.2 Create a Placeholder
          logger.debug { 'Creating Placeholder.' }
          #placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :group => [ 'Film' ], :timespan => [ { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ], :start => '-INF', :end => '+INF' } ] } }
          #placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :timespan => [ { :start => '-INF', :end => '+INF' }.merge(_metadata_as_fields) ] } }
          #placeholder_args = args[:placeholder_args] ||= { :container => 1, :metadata_document => { :timespan => [ { :start => '-INF', :end => '+INF' }.merge(_metadata_as_fields) ] } }
          placeholder_args = args[:placeholder_args] ||= { :container => 1, :metadata_document => metadata_document }
          _response[:item] = item = import_placeholder(placeholder_args)
        end
        item_id = item['id']
        shape = item['shape']

        raise "Error Creating Placeholder: #{item.inspect}" unless item_id

        # Add any additional metadata (Vidispine will only take one group at a time)
        metadata_documents.each do |metadata_document|
          item_metadata_set(:item_id => item_id, :metadata_document => metadata_document)
        end

        if options[:add_item_to_collection]
          logger.debug { 'Determining Collection to Add the Item to.' }
          collection = determine_collection(args, options)
          _response[:collection] = collection
          collection_id = collection['id']

          logger.debug { 'Adding Item to Collection.' }
          collection_object_add_response = collection_object_add(:collection_id => collection_id, :object_id => item_id)
          _response[:collection_object_add] = collection_object_add_response
        end

        unless shape
          # 6. Add the file as the original shape
          logger.debug { 'Adding the file as the Original Shape.' }
          item_shape_import_response = item_shape_import(:item_id => item_id, :file_id => file_id, :tag => 'original')
          _response[:item_shape_import] = item_shape_import_response

          job_id = item_shape_import_response['jobId']
          unless job_id
            invalid_input = item_shape_import_response['invalidInput']
            if invalid_input
              explanation = invalid_input['explanation']
              job_id = $1 if explanation.match(/.*\[(.*)\]$/)
            end
          end
          raise "Error Creating Item Shape Import Job. Response: #{item_shape_import_response.inspect}" unless job_id

          job_monitor_response = wait_for_job_completion(:job_id => job_id) { |env|
            logger.debug { "Waiting for Item Shape Import Job to Complete. Time Elapsed: #{Time.now - env[:time_started]} seconds" }
          }
          last_response = job_monitor_response[:last_response]
          raise "Error Adding file As Original Shape. Response: #{last_response.inspect}" unless last_response['status'] == 'FINISHED'

          # 7. Generate the Transcode of the item
          transcode_tag = args.fetch(:transcode_tag, 'lowres')
          if transcode_tag and !transcode_tag.empty? and transcode_tag.to_s.downcase != 'false'
            wait_for_transcode_job = options[:wait_for_transcode_job]
            skip_transcode_if_shape_with_tag_exists = options.fetch(:skip_transcode_if_shape_with_tag_exists, true)
            [*transcode_tag].each do |_transcode_tag|
              transcode_response = item_transcode_extended({
                                                             :item_id => item_id,
                                                             :transcode_tag => _transcode_tag
                                                           },
                                                           {
                                                             :wait_for_transcode_job => wait_for_transcode_job,
                                                             :skip_if_shape_with_tag_exists => skip_transcode_if_shape_with_tag_exists
                                                           })
              (_response[:transcode] ||= { })[transcode_tag] = transcode_response

              # each transcode_tag
            end

            # if transcode_tag
          end

          # 8. Generate the Thumbnails and Poster Frame
          create_thumbnails = args.fetch(:create_thumbnails, true)
          create_posters = args.fetch(:create_posters, 3)
          if (create_thumbnails or create_posters)
            logger.debug { 'Generating Thumbnails(s) and Poster Frame.' }
            args_out = { :item_id => item_id }
            args_out[:create_thumbnails] = create_thumbnails if create_thumbnails
            args_out[:create_posters] = create_posters if create_posters
            item_thumbnail_response = item_thumbnail(args_out)
            _response[:item_thumbnail] = item_thumbnail_response
          end
        end

        _response
      end

      # Add an item to the system using file path metadata field as the key
      # 1. Search for pre existing asset
      # 2. Create a placeholder with metadata (if asset doesn't exist)
      # 3. Create an original shape.
      # 4. Poll the Job status of the shape creation
      # 5. Trigger the Transcode of the Proxy, thumbnails
      # 6. Trigger the Transcode of the thumbnail.
      # 7. Trigger the Transcode of the poster frame
      # This was an early experiment
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
        raise "Error Retrieving Storage Record. Storage Id: #{storage.inspect}" unless storage

        storage_id = storage['id']
        storage_uri_raw = storage['method'].first['uri']
        storage_uri = URI.parse(storage_uri_raw)

        vidispine_file_path = File.join(storage_uri.path, file_path_relative_to_storage_path)
        logger.debug { "Vidispine File Path: '#{vidispine_file_path}'" }
        _response[:vidispine_file_path] = vidispine_file_path

        _metadata = args[:metadata] || { }
        _metadata[metadata_file_path_field_id] ||= vidispine_file_path

        _metadata_map = args[:metadata_map] || { }

        # map metadata assuming 1 value per field
        _metadata_as_fields = transform_metadata_to_fields(_metadata, _metadata_map, options)

        # 4.1 Search for Item using File Path
        search_response = search(:content => 'metadata', :item_search_document => { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ] } ) || { 'entry' => [ ] }
        _response[:search] = search_response

        item = (search_response['entry'].first || { })['item']
        unless item
          # If the item wasn't found then get the file id for the file
          # 4.1 Search for the storage file record
          storage_file_get_response = storage_files_get(:storage_id => storage_id, :path => file_path_relative_to_storage_path) || { 'file' => [ ] }
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
          placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :timespan => [ { :start => '-INF', :end => '+INF' }.merge(_metadata_as_fields) ] } }
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

      def item_shape_add_using_file_path(args = { }, options = { })
        logger.debug { "#{__method__}:#{args.inspect}" }
        _response = { }

        storage_path_map = args[:storage_path_map]

        item = args[:item] || { }
        item_id = args[:item_id] || item['id']

        tag = args[:tag]

        file = args[:file] || { }
        file_id = args[:file_id] || file['id']

        unless file_id

          storage = args[:storage] || { }
          storage_id = args[:storage_id] || storage['id']

          file_path = args[:file_path]
          file_path_relative_to_storage_path = args[:relative_file_path]

          unless file_path_relative_to_storage_path
            if storage_id
              # Process file path using storage information
            else
              process_file_path_response = process_file_path_using_storage_map(file_path, storage_path_map)
            end

            file_path_relative_to_storage_path = process_file_path_response[:relative_file_path]
            storage_id ||= process_file_path_response[:storage_id]
          end

          file = storage_file_get_or_create(storage_id, file_path_relative_to_storage_path)

          file_id = file['id']
          raise "File Error: #{file} Response: #{_response}" unless file_id
        end

        item_shape_import_args = { :item_id => item_id, :file_id => file_id, :tag => tag }
        item_shape_import(item_shape_import_args)
      end
      alias :item_add_shape_using_file_path :item_shape_add_using_file_path

      #
      # @param [Hash] args
      # @param [Hash] options
      def item_shapes_get_extended(args = { }, options = { })
        item_id = args[:item_id]
        tag = args[:tag]
        return_as_hash = options.fetch(:return_as_hash, false)

        if return_as_hash
          key_by_field = options[:hash_key] || 'id'
        end

        shapes_response = item_shapes_get(:item_id => item_id, :tag => tag)

        shape_ids = shapes_response['uri'] || [ ]
        shapes = [ ]
        shape_ids.each do |shape_id|
          shape = item_shape_get(:item_id => item_id, :shape_id => shape_id)
          shape.dup.each do |k, v|
            shape[k] = v.first if v.is_a?(Array) and v.length == 1 and !['metadata'].include?(k)
          end
          shapes << shape
        end

        shapes_formatted = return_as_hash ? Hash[ shapes.map { |v| [ v[key_by_field], v ] } ] : shapes

        shapes_response['shapes'] = shapes_formatted
        shapes_response
      end

      # @param [Hash] args
      # @param [Hash] options
      # @option options [Boolean] :skip_if_shape_with_tag_exists
      def item_transcode_shape(args = { }, options = { })
        _response = { }
        item_id = args[:item_id]
        transcode_tag = args[:tag] || args[:transcode_tag] || 'lowres'
        skip_if_tag_exists = options.fetch(:skip_if_shape_with_tag_exists, false)

        if skip_if_tag_exists
          item_shapes_response = item_shapes_get(:item_id => item_id, :tag => transcode_tag)
          shape_ids = item_shapes_response['uri'] || [ ]
          proxy_shape_id = shape_ids.last
          _response[:tag_existed_on_shape] = !!proxy_shape_id
        end

        unless proxy_shape_id
          logger.debug { "Generating Transcode of the Item. Tag: '#{transcode_tag}'" }
          item_transcode_response = item_transcode(:item_id => item_id, :tag => transcode_tag)
          _response[:item_transcode] = item_transcode_response

          if options[:wait_for_transcode_job]
            job_id = item_transcode_response['jobId']
            job_monitor_callback = options[:job_monitor_callback_function]
            job_monitor_response = wait_for_job_completion(:job_id => job_id) do |env|
              logger.debug { "Waiting for '#{transcode_tag}' Transcode Job to Complete. Time Elapsed: #{Time.now - env[:time_started]} seconds" }
              job_monitor_callback.call(env) if job_monitor_callback
            end

            last_response = job_monitor_response[:last_response]
            if last_response['status'] == 'FINISHED'
              data = last_response['data']
              data = Hash[ data.map { |d| [ d['key'], d['value'] ] } ]

              proxy_shape_ids = data['shapeIds']
              proxy_shape_id = proxy_shape_ids
            end

            # if wait_for_transcode_job
          end

        end

        if proxy_shape_id
          item_shape_files = item_shape_files_get(:item_id => item_id, :shape_id => proxy_shape_id)
          proxy_file = (((item_shape_files || { })['file'] || [ ]).first || { })
          proxy_file_uri = (proxy_file['uri'] || [ ]).first
          _response[:file] = proxy_file
          _response[:shape_id] = proxy_shape_id
          _response[:file_uri] = proxy_file_uri
          _response[:file_path] = URI.decode(URI(proxy_file_uri).path)
        end

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
        storage_path_map = args[:storage_path_map] || args[:storage_map]
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
          storage_file_get_or_create_response = storage_file_get_or_create(storage_id, file_path_relative_to_storage_path, :extended_response => true)
          _response[:storage_file_get_or_create_response] = storage_file_get_or_create_response
          file = storage_file_get_or_create_response[:file]

          item = placeholder = file['item']

          unless item
            # 4.2 Create a Placeholder
            logger.debug { 'Creating Placeholder.' }
            #placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :group => [ 'Film' ], :timespan => [ { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ], :start => '-INF', :end => '+INF' } ] } }
            placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1, :metadata_document => { :timespan => [ { :field => [ { :name => metadata_file_path_field_id, :value => [ { :value => vidispine_file_path } ] } ], :start => '-INF', :end => '+INF' } ] } }
            item = placeholder = import_placeholder(placeholder_args)
          end
          _response[:placeholder] = placeholder
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
        if job_id
          job_monitor_response = wait_for_job_completion(:job_id => job_id) { |env|
            logger.debug { "Waiting for Item Shape Import Job to Complete. Time Elapsed: #{Time.now - env[:time_started]} seconds" }
          }
          last_response = job_monitor_response[:last_response]
          raise "Error Adding file As Original Shape. Response: #{last_response.inspect}" unless last_response['status'] == 'FINISHED'
          _response[:item_shape_import_job] = job_monitor_response
        end

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

      # SEQUENCE THAT CREATES AN ITEM AND THE PROXY USING THE FILE ID
      # @param [Hash] args
      # @option args [String] :original_file_path
      # @option args [String] :lowres_file_path
      # @option args [String] :storage_id
      # @option args [Hash] :placeholder_args ({ :container => 1, :video => 1 })
      # @option args [Boolean] :create_posters (False)
      # @option args [Boolean] :create_thumbnails (True)
      def item_create_with_proxy_using_storage_file_paths(args = { }, options = { })

        original_file_path = args[:original_file_path] || args[:original]
        lowres_file_path = args[:lowres_file_path] || args[:lowres]

        placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1 }

        storage_id = args[:storage_id]

        create_posters = args[:create_posters] #|| '300@NTSC'
        create_thumbnails = args.fetch(:create_thumbnails, true)

        # Create a placeholder
        # /API/import/placeholder/?container=1&video=1
        logger.debug { "Creating Placeholder: #{placeholder_args.inspect}" }
        place_holder = import_placeholder(placeholder_args)
        item_id = place_holder['id']

        raise 'Placeholder Create Failed.' unless success?

        # /API/storage/VX-2/file/?path=storages/test/test_orginal2.mp4
        _original_file = original_file = storage_file_get(:storage_id => storage_id, :path => original_file_path)
        raise "Unexpected Response Format. Expecting Hash instead of #{original_file.class.name} #{original_file}" unless _original_file.is_a?(Hash)

        original_file = original_file['file']
        begin
          original_file = original_file.first
        rescue => e
          raise "Error Getting File from Response. #{$!}\n#{original_file.inspect}\n#{_original_file.inspect}"
        end
        raise "File Not Found. '#{original_file_path}' in storage '#{storage_id}'" unless original_file
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

      def items_search_extended(args = { }, options = { })
        _args = symbolize_keys(args, false)
        _data = Requests::BaseRequest.process_parameters([ { :name => :fields }, { :name => :item_search_document } ], _args)
        _args = _args.merge(_data[:arguments_out])

        fields = _args.delete(:fields)
        _args[:item_search_document] ||= build_item_search_document(:fields => fields)

        items_search(_args, options)
      end
      alias :item_search_extended :items_search_extended

      # Will process a file path through a storage path map
      # @param [String] file_path
      # @param [Hash] storage_path_map (#storage_file_path_map_create)
      # @return [Hash] :relative_file_path, :storage_id, :storage_path_map, :volume_path
      def process_file_path_using_storage_map(file_path, storage_path_map = nil)
        logger.debug { "Method: #{__method__} Args: #{{:file_path => file_path, :storage_path_map => storage_path_map}.inspect}"}

        storage_path_map = storage_file_path_map_create unless storage_path_map and !storage_path_map.empty?

        volume_path, storage_id = storage_path_map.find { |path, _| file_path.start_with?(path) }
        file_path_relative_to_storage_path = file_path.sub(volume_path, '')

        _response = { :relative_file_path => file_path_relative_to_storage_path,
                      :storage_id => storage_id,
                      :storage_path_map => storage_path_map,
                      :volume_path => volume_path }

        logger.debug { "Method: #{__method__} Response: #{_response.inspect}" }
        _response
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
        _params = Requests::StorageFileCreate::PARAMETERS.concat [ { :name => :directory, :aliases => [ :dir ], :send_in => :none }, { :name => :storage_map, :send_in => :none } ]
        _data = Requests::BaseRequest.process_parameters(_params, _args)
        _args = _args.merge(_data[:arguments_out])

        storage_path_map = _args.delete(:storage_map) { }
        if storage_path_map.empty?
          storage_path_map = storage_file_path_map_create
        else
          storage_path_map = Hash[storage_path_map.map { |k,v| [k.to_s, v] }] if storage_path_map.is_a?(Hash)
        end


        dir = _args.delete(:directory) { }
        if dir
          # raise ArgumentError, ':storage_map is a required argument.' unless storage_path_map

          volume_path, storage = storage_path_map.find { |path, _| dir.start_with?(path) }
          raise "Unable to find match in storage path map for '#{dir}'. Storage Map: #{storage_path_map.inspect}" unless volume_path

          dir_path_relative_to_storage = dir.sub(volume_path, '')

          storage = storage_get(:id => storage) if storage.is_a?(String)
          raise 'Error Retrieving Storage Record. Storage Id: #{' unless storage

          storage_id = storage['id']
          _args[:storage_id] = storage_id
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
      # @option args [String] :file_path
      # @option args [Hash] :storage_path_map
      # @option args [Boolean] :create_if_not_exists (True)
      # @option args [Boolean] :include_item (True)
      def storage_file_get_using_file_path(args = { })
        _response = { }
        file_path = args[:file_path]
        storage_path_map = args[:storage_path_map] || storage_file_path_map_create
        storage_path_map = storage_file_path_map_create if storage_path_map.empty?

        volume_path, storage = storage_path_map.find { |path, _| file_path.start_with?(path) }
        raise "Unable to find match in storage path map for '#{file_path}'. Storage Map: #{storage_path_map.inspect}" unless volume_path

        file_path_relative_to_storage_path = file_path.sub(volume_path, '')
        logger.debug { "File Path Relative to Storage Path: #{file_path_relative_to_storage_path}" }

        storage = storage_get(:id => storage) if storage.is_a?(String)
        _response[:storage] = storage
        storage_id = storage['id']
        raise "Error Retrieving Storage Record. Storage: #{storage}" unless storage_id

        # The method type of the URI to lookup
        storage_method_type = args[:storage_method_type] ||= 'file'

        storage_uri_method = "#{storage_method_type}:"
        storage_uri_raw = (storage['method'].find { |v| v['uri'].start_with?(storage_uri_method) } || { })['uri'] rescue nil
        raise "Error Getting URI from Storage Method. Storage: #{storage.inspect}" unless storage_uri_raw
        storage_uri = URI.parse(storage_uri_raw)

        vidispine_file_path = File.join(storage_uri.path, file_path_relative_to_storage_path)
        logger.debug { "Vidispine File Path: '#{vidispine_file_path}'" }

        create_if_not_exists = args.fetch(:create_if_not_exists, true)
        include_item = args.fetch(:include_item, true)
        options_out = { :include_item => include_item }
        if create_if_not_exists
          storage_file_get_or_create_response = storage_file_get_or_create(storage_id, file_path_relative_to_storage_path, options_out.merge(:extended_response => true))
          _response[:storage_file_get_or_create_response] = storage_file_get_or_create_response
          file = storage_file_get_or_create_response[:file]
        else
          storage_file_get_response = storage_files_get({ :storage_id => storage_id, :path => file_path_relative_to_storage_path }.merge(options_out)) || { 'file' => [ ] }
          file = ((storage_file_get_response || { })['file'] || [ ]).first
        end

        file
      end

      # Will search for a relative file path on a storage and if not found will trigger a storage_file_create
      # @param [String] storage_id
      # @param [String] file_path_relative_to_storage_path
      def storage_file_get_or_create(storage_id, file_path_relative_to_storage_path, options = { })
        logger.debug { "Method: #{__method__} Args:#{{:storage_id => storage_id, :file_path_relative_to_storage_path => file_path_relative_to_storage_path, :options => options }.inspect}" }
        include_item = options.fetch(:include_item, true)
        creation_state = options[:creation_state] || 'CLOSED'
        storage_file_get_response = storage_files_get(:storage_id => storage_id, :path => file_path_relative_to_storage_path, :include_item => include_item) || { 'file' => [ ] }
        file = ((storage_file_get_response || { })['file'] || [ ]).first
        if file
          file_already_existed = true
        else
          file_already_existed = false
          # 4.1.1 Create the storage file record if it does not exist
          storage_file_create_response = file = storage_file_create(:storage_id => storage_id, :path => file_path_relative_to_storage_path, :state => creation_state)
          if (file || { })['fileAlreadyExists']
            file_already_existed = true
            _message = file['fileAlreadyExists']
            logger.warn { "Running Recreation of Existing File Work Around: #{_message}" }
            storage_file_get_response = file = storage_file_get(:storage_id => storage_id, :file_id => _message['fileId'], :include_item => include_item)
          end
          raise "Error Creating File on Storage. Response: #{response.inspect}" unless (file || { })['id']
        end

        logger.debug { "Method: #{__method__} Response: #{file.inspect}" }

        if options[:extended_response]
          return {
            :file => file,
            :file_already_existed => file_already_existed,
            :storage_file_get_response => storage_file_get_response,
            :storage_file_create_response => storage_file_create_response
          }
        end
        file
      end

      # Generates a storage file path map from the current storages.
      # This is meant as a default, on most methods you can provide your own storage map that can be used to resolve
      # local paths to storage paths.
      # This particular method is builds using file method addresses only.
      def storage_file_path_map_create
        storages_response = storages_get
        storages = storages_response['storage']
        storage_file_path_map = { }
        storages.each do |storage|
          storage_methods = storage['method']
          file_storage_method = storage_methods.find { |m| m['uri'].start_with?('file:') }
          next unless file_storage_method
          uri = file_storage_method['uri']
          match = uri.match(/(.*):\/\/(.*)/)
          address = match[2]
          storage_file_path_map[address] = storage['id']
        end
        storage_file_path_map
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
          break if %w(FAILED_TOTAL FINISHED FINISHED_WARNING FINISHED_TOTAL ABORTED).include?(job_status)

          break if timeout and (timed_out = ((Time.now - time_started) > timeout))

          if block_given?
            yield_out = {
              :time_started => time_started,
              :poll_interval => delay,
              :latest_response => _response,
              :job_status => job_status,
              :continue_monitoring => continue_monitoring,
              :delay => delay
            }
            yield yield_out
            break unless continue_monitoring
          else
            logger.debug { "Waiting for job completion. Job: #{job_status} Poll Interval: #{delay}" }
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