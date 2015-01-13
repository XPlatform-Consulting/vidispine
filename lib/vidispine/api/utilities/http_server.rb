require 'pp'

require 'sinatra/base'
require 'vidispine/api/utilities'

module Vidispine

  module API

    class Utilities

      class HTTPServer < Sinatra::Base

        configure do
          enable :show_exceptions
          enable :dump_errors
          #enable :lock # ensure single request concurrency with a mutex lock
        end

        DEFAULT_ADDRESS_BINDING = 'localhost'
        DEFAULT_PORT = '8080'

        attr_accessor :global_arguments,
                      :metadata_file_path_field_id,
                      :relative_file_path_collection_name_position,
                      :storage_path_map

        # @!group Routes

        get '/collection-by-name/:collection_name' do
          log_request_match(__method__)
          _response = api.dup.collection_get_by_name(params)
          logger.debug { "Response: #{_response}" }
          format_response(_response)
        end

        post '/collection-file-add-using-path/?' do
          log_request_match(__method__)
          _params = merge_params_from_body

          #args_out = _params
          args_out = indifferent_hash.merge({
            :storage_path_map => initial_arguments[:storage_path_map],
            :relative_file_path_collection_name_position => initial_arguments[:relative_file_path_collection_name_position],
            :metadata_file_path_field_id => initial_arguments[:metadata_file_path_field_id],
          })

          args_out.merge!(_params)
          _response = api.dup.collection_file_add_using_path(args_out)
          format_response(_response)
        end

        # Shows what gems are within scope. Used for diagnostics and troubleshooting.
        get '/gems' do
          stdout_str = `gem list -b`
          stdout_str ? stdout_str.gsub("\n", '<br/>') : stdout_str
        end

        get '/favicon.ico' do; end

        get '/:method_name?' do
          logger.debug { "GET #{params.inspect}" }
          method_name = params[:method_name]
          pass unless api.respond_to?(method_name)
          log_request_match(__method__)
          _params = merge_params_from_body

          _response = api.dup.send(method_name, _params)
          format_response(_response)
        end

        post '/:method_name?' do
          logger.debug { "POST #{params.inspect}" }
          method_name = params[:method_name]
          pass unless api.respond_to?(method_name)
          log_request_match(__method__)

          _params = merge_params_from_body

          _response = api.dup.send(method_name, _params)
          format_response(_response)
        end



        ### CATCH ALL ROUTES BEGIN
        get /.*/ do
          log_request_match(__method__)
          request_to_s.gsub("\n", '<br/>')
        end

        post /.*/ do
          log_request_match(__method__)
        end
        ### CATCH ALL ROUTES END

        # @!endgroup Routes

        def format_response(response, args = { })
          supported_types = %w(application/json application/xml text/xml)
          case request.preferred_type(supported_types)
            when 'application/json'
              content_type :json
              _response = (response.is_a?(Hash) || response.is_a?(Array)) ? JSON.generate(response) : response
            #when 'application/xml', 'text/xml'
            #  content_type :xml
            #  _response = XmlSimple.xml_out(response, { :root_name => 'response' })
            else
              content_type :json
              _response = (response.is_a?(Hash) || response.is_a?(Array)) ? JSON.generate(response) : response
          end
          _response
        end # output_response

        def parse_body
          if request.media_type == 'application/json'
            request.body.rewind
            body_contents = request.body.read
            logger.debug { "Parsing: '#{body_contents}'" }
            if body_contents
              json_params = JSON.parse(body_contents)
              return json_params
            end
          end

        end # parse_body

        # Will try to convert a body to parameters and merge them into the params hash
        # Params will override the body parameters
        #
        # @params [Hash] _params (params) The parameters parsed from the query and form fields
        def merge_params_from_body(_params = params)
          _params = _params.dup
          _params_from_body = parse_body
          _params = _params_from_body.merge(_params) if _params_from_body.is_a?(Hash)
          indifferent_hash.merge(_params)
        end # merge_params_from_body

        # @param [Hash] args
        # @option args [Request] :request
        def request_to_s(args = { })
          _request = args[:request] || request
          output = <<-OUTPUT
------------------------------------------------------------------------------------------------------------------------
    REQUEST
    Method:         #{_request.request_method}
    URI:            #{_request.url}

    Host:           #{_request.host}
    Path:           #{_request.path}
    Script Name:    #{_request.script_name}
    Query String:   #{_request.query_string}
    XHR?            #{_request.xhr?}

    Remote
    Host:           #{_request.env['REMOTE_HOST']}
    IP:             #{_request.ip}
    User Agent:     #{_request.user_agent}
    Cookies:        #{_request.cookies}
    Accepts:        #{_request.accept}
    Preferred Type: #{_request.preferred_type}

    Media Type:     #{_request.media_type}
    BODY BEGIN:
#{_request.body.read}
    BODY END.

    Parsed Parameters:
    #{PP.pp(_request.params, '', 60)}

------------------------------------------------------------------------------------------------------------------------
          OUTPUT
          _request.body.rewind
          output
        end # request_to_s

        def log_request(route = '')
          return if request.path == '/favicon.ico'
          logger.debug { "\n#{request_to_s}" }
          #puts requests.insert(request_to_hash)
        end # log_request

        def log_request_match(route)
          log_request(route)
          logger.debug { "MATCHED: #{request.url} -> #{route}\nParsed Parameters: #{params.inspect}" }
        end # log_request_match

        def self.initialize_logger(args = { })
          logger = args[:logger] ||= Logger.new(args[:log_to] || STDOUT)
          logger.level = args[:log_level] if args[:log_level]
          logger
        end

        # @param [Hash] args
        # @option args [Logger] :logger
        # @option args [String] :binding
        # @option args [String] :local_port
        def self.init(args = {})
          logger = initialize_logger(args)
          set(:logger, logger)

          logger.debug { "Initializing HTTP Server. Arguments: #{args.inspect}" }

          _binding = args.delete(:binding) { DEFAULT_ADDRESS_BINDING }
          _port = args.delete(:port) { DEFAULT_PORT }
          set(:bind, _binding)
          set(:port, _port)
          set(:initial_arguments, args)

          set(:api, args[:api])
        end

        def logger
          #self.class.logger
          settings.logger
        end

        def api
          #self.class.api
          settings.api
        end

      end

    end

  end

end

