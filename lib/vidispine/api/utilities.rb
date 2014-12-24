require 'vidispine/api/client'

module Vidispine

  module API

    class Utilities < Client

      # SEQUENCE THAT CREATE AN ITEM AND THE PROXY USING THE FILE ID
      def item_create_with_proxy_using_file_id(args = { }, options = { })
        # metadata = args[:metadata]
        # metadata = metadata.map { |k,v| { 'name' => k, 'value' => v } } if metadata.is_a?(Hash)
        #
        # collection_id = args[:collection_id]
        # unless collection_id
        #   collection_name = args[:collection_name ]
        #   unless collection_name
        #     raise ArgumentError, 'collection_id or collection_name is required.'
        #   end
        #
        #   collection = collection_get_by_name( { :collection_name => collection_name } )
        #
        #   unless collection
        #     collection_create_if_not_exist = args[:collection_create_if_not_exist]
        #     unless collection_create_if_not_exist
        #       raise Argument, "collection not found. '#{collection_name}'"
        #     end
        #
        #     # Create Collection
        #     collection = collection_create(collection_name)
        #   end
        #
        #   collection_id = collection['id']
        # end

        original_file_path = args[:original_file_path] || args[:original]
        lowres_file_path = args[:lowres_file_path] || args[:lowres]

        placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1 }

        storage_id = args[:storage_id]

        # Create a placeholder
        # /API/import/placeholder/?container=1&video=1
        place_holder = placeholder_create(placeholder_args)
        item_id = place_holder['id']

        # /API/storage/VX-2/file/?path=storages/test/test_orginal2.mp4
        original_file = storage_file_get(:storage_id => storage_id, :path => original_file_path)
        original_file_id = original_file['file'].first['id']

        # /API/item/VX-98/shape?tag=original&fileId=[FileIDofOriginal]
        item_shape_import(:item_id => item_id, :tag => 'original', :file_id => original_file_id)

        # /API/storage/VX-2/file/?path=storages/test/test_proxy2.mp4
        lowres_file = storage_file_get(:storage_id => storage_id, :path => lowres_file_path)
        lowres_file_id = lowres_file['file'].first['id']

        # /API/item/VX-98/shape?tag=lowres&fileId=[FileIDofProxy]
        item_shape_import(:item_id => item_id, :tag => 'lowres', :file_id => lowres_file_id)

        # /API/item/VX-98/thumbnail/?createThumbnails=true&createPoster
        item_transcode(:item_id => item_id, :type => 'thumbnail', :create_thumbnails => true, :tag => 'original,lowres')

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

      def collection_get_by_name(args = { }, options = { })
        collection_name = args[:collection_name] || args[:name]
        return_first_match = options.fetch(:return_first_match, true)

        unless collection_name
          raise ArgumentError, 'collection_name is required.'
        end

        collections = ( (collections_get || { })['collections'] || [ ] )

        return collections.find { |c| c['name'] == collection_name } if return_first_match
        collections.select { |c| c['name'] == collection_name }
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
            :http_path => 'v1/item/#{arguments[item_id]}/annotation',
            :http_method => :post,
            :default_parameter_send_in_value => :body,
            :parameters => [
              { :name => :item_id, :aliases => [ :id ], :required => true, :send_in => :path },

              :inpoint,
              :output,
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

      # Utilities
    end

    # API
  end

  # Vidispine
end