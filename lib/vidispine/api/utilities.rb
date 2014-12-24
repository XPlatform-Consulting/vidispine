require 'vidispine/api/client'

module Vidispine

  module API

    class Utilities < Client

      def asset_create(args = { }, options = { })
        original = args[:original]
        lowres = args[:lowres]

        metadata = args[:metadata]
        metadata = metadata.map { |k,v| { 'name' => k, 'value' => v } } if metadata.is_a?(Hash)

        placeholder_args = args[:placeholder_args] ||= { :container => 1, :video => 1 }

        collection_id = args[:collection_id]
        unless collection_id
          collection_name = args[:collection_name ]
          unless collection_name
            raise ArgumentError, 'collection_id or collection_name is required.'
          end

          collection = collection_get_by_name( { :collection_name => collection_name } )

          unless collection
            collection_create_if_not_exist = args[:collection_create_if_not_exist]
            unless collection_create_if_not_exist
              raise Argument, "collection not found. '#{collection_name}'"
            end

            # Create Collection
            collection = collection_create(collection_name)
          end

          collection_id = collection['id']
        end


        # Create a placeholder
        place_holder = placeholder_create(placeholder_args)

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
            :http_path => 'v1/item/#{item_id/annotation',
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