require 'json'
require 'net/https'

module Vidispine
  module API
    class Client

      class HTTPClient

        class HTTPAuthorizationError < RuntimeError; end

        attr_accessor :logger, :http, :http_host_address, :http_host_port, :base_uri, :default_base_path,
                      :default_query_data
        attr_accessor :username, :password

        attr_accessor :default_request_headers,
                      :authorization_header_key, :authorization_header_value

        attr_accessor :log_request_body, :log_response_body, :log_pretty_print_body

        attr_accessor :request, :response, :use_exceptions

        DEFAULT_HTTP_HOST_ADDRESS = 'localhost'
        DEFAULT_HTTP_HOST_PORT = 8080

        DEFAULT_USERNAME = 'admin'
        DEFAULT_PASSWORD = 'password'
        DEFAULT_BASE_PATH = '/'

        DEFAULT_HEADER_CONTENT_TYPE = 'application/json; charset=utf-8'
        DEFAULT_HEADER_ACCEPTS = 'application/json'

        def initialize(args = { })
          args = args.dup

          @use_exceptions = args.fetch(:use_exceptions, true)

          initialize_logger(args)
          initialize_http(args)

          logger.debug { "#{self.class.name}::#{__method__} Arguments: #{args.inspect}" }

          @base_uri = args[:base_uri] || "http#{http.use_ssl? ? 's' : ''}://#{http.address}:#{http.port}"
          @default_base_path = args.fetch(:default_base_path, DEFAULT_BASE_PATH)

          @default_query_data = args[:default_query_data] || { }

          # @user_agent_default = "#{@hostname}:#{@username} Ruby SDK Version #{Vidispine::VERSION}"

          @username = args[:username] || DEFAULT_USERNAME
          @password = args[:password] || DEFAULT_PASSWORD

          @authorization_header_key = args.fetch(:authorization_header_key, 'Authorization')
          @authorization_header_value = args.fetch(:authorization_header_value,
                                                   %(Basic #{["#{username}:#{password}"]
                                                                 .pack('m')
                                                                 .delete("\r\n")}))

          content_type = args[:content_type_header] ||= DEFAULT_HEADER_CONTENT_TYPE
          accepts = args[:accepts_header] ||= args[:accept_header] || DEFAULT_HEADER_ACCEPTS

          @default_request_headers = {
            'Content-Type' => content_type,
            'Accept' => accepts,
            authorization_header_key => authorization_header_value,
          }

          @log_request_body = args.fetch(:log_request_body, true)
          @log_response_body = args.fetch(:log_response_body, true)
          @log_pretty_print_body = args.fetch(:log_pretty_print_body, true)

          @parse_response = args.fetch(:parse_response, true)
        end

        def initialize_logger(args = { })
          @logger = args[:logger] ||= Logger.new(args[:log_to] || STDOUT)
          log_level = args[:log_level]
          if log_level
            @logger.level = log_level
            args[:logger] = @logger
          end
          @logger
        end

        def initialize_http(args = { })
          @http_host_address = args[:http_host_address] ||= DEFAULT_HTTP_HOST_ADDRESS
          @http_host_port = args[:http_host_port] ||= DEFAULT_HTTP_HOST_PORT
          @http = Net::HTTP.new(http_host_address, http_host_port)
          use_ssl = args[:http_host_use_ssl]
          if use_ssl
            http_verify_mode = args.fetch(:http_verify_mode, OpenSSL::SSL::VERIFY_NONE)
            http.use_ssl = true
            http.verify_mode = http_verify_mode if http_verify_mode
          end

          http
        end

        # Formats a HTTPRequest or HTTPResponse body for log output.
        # @param [HTTPRequest|HTTPResponse] obj
        # @return [String]
        def format_body_for_log_output(obj)
          if obj.content_type == 'application/json'
            if @log_pretty_print_body
              _body = obj.body
              output = JSON.pretty_generate(JSON.parse(_body)) rescue _body
              return output
            else
              return obj.body
            end
          elsif obj.content_type == 'application/xml'
            return obj.body
          else
            return obj.body.inspect
          end
        end

        # @param [HTTPRequest] request
        def send_request(request)
          @response_parsed = nil
          @request = request
          logger.debug { %(REQUEST: #{request.method} http#{http.use_ssl? ? 's' : ''}://#{http.address}:#{http.port}#{request.path} HEADERS: #{request.to_hash.inspect} #{log_request_body and request.request_body_permitted? ? "\n-- BODY BEGIN --\n#{format_body_for_log_output(request)}\n-- BODY END --" : ''}) }

          @request_time_start = Time.now
          @response = http.request(request)
          @request_time_end = Time.now
          logger.debug { %(RESPONSE: #{response.inspect} HEADERS: #{response.to_hash.inspect} #{log_response_body and response.respond_to?(:body) ? "\n-- BODY BEGIN --\n#{format_body_for_log_output(response)}\n-- BODY END--" : ''}\nTook: #{@request_time_end - @request_time_start} seconds) }
          #logger.debug { "Parse Response? #{@parse_response}" }

          raise HTTPAuthorizationError if @use_exceptions && @response.code == '401'

          @parse_response ? response_parsed : response.body
        end

        def response_parsed
          @response_parsed ||= begin
            response_body = response.respond_to?(:body) ? response.body : ''
            logger.debug { "Parsing Response. #{response_body.inspect}" }

            case response.content_type
            when 'application/json'
               response_body.empty? ? response_body : JSON.parse(response_body) # rescue response
             else
               response_body
            end
          end
        end

        # Compiles a full URI
        #
        # @param [String] path
        # @param [Hash|String|Nil] query
        # @param [Hash] options
        # @option options [Hash] :default_query_data
        # @option options [Hash] :default_base_path
        #
        # @return [URI]
        def build_uri(path = '', query = nil, options = { })
          _default_query_data = options.fetch(:default_query_data, default_query_data) || { }
          _default_base_path = options.fetch(:default_base_path, default_base_path)

          query = { } if query.nil?

          _query = query.is_a?(Hash) ? (default_query_data.merge(query)).map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.respond_to?(:to_s) ? v.to_s : v)}" }.join('&') : query
          _path = "#{path}#{_query and _query.respond_to?(:empty?) and !_query.empty? ? "?#{_query}" : ''}"
          _path = File.join(_default_base_path, _path) if _default_base_path
          _path = File.join(base_uri, _path)
          URI.parse(_path)
        end

        if RUBY_VERSION.start_with? '1.8.'
          def request_method_name_to_class_name(method_name)
            method_name.to_s.capitalize
          end
        else
          def request_method_name_to_class_name(method_name)
            method_name.to_s.capitalize.to_sym
          end
        end

        # Builds the HTTP request
        #
        # @param [Symbol] method_name (:get)
        # @param [Hash] args
        # @option args [Hash] :headers ({})
        # @option args [String] :path ('')
        # @option args [Hash] :query ({})
        # @option args [Any] :body (nil)
        # @param [Hash] options
        # @option options [Hash] :default_request_headers (@default_request_headers)
        def build_request(method_name = :get, args = { }, options = { })
          headers = args[:headers] || options[:headers] || { }
          path = args[:path] || ''
          query = args[:query] || { }
          body = args[:body]

          # Allow the default request headers to be overridden
          _default_request_headers = options.fetch(:default_request_headers, default_request_headers)
          _default_request_headers ||= { }
          _headers = _default_request_headers.merge(headers)

          @uri = build_uri(path, query, options)
          klass_name = request_method_name_to_class_name(method_name)
          klass = Net::HTTP.const_get(klass_name)

          _request = klass.new(@uri.request_uri, _headers)

          if _request.request_body_permitted?
            _body = (body and !body.is_a?(String)) ? JSON.generate(body) : body
            logger.debug { "Processing Body: '#{_body}'" }
            _request.body = _body if _body
          end

          _request
        end

        # First builds and then sends the HTTP request
        #
        # @param [Symbol] method_name (:get)
        # @param [Hash] args
        # @option args [Hash] :headers ({})
        # @option args [String] :path ('')
        # @option args [Hash] :query ({})
        # @option args [Any] :body (nil)
        #
        # @param [Hash] options
        # @option options [Hash] :default_request_headers (@default_request_headers)
        def build_and_send_request(method_name = :get, args = { }, options = { })
          _request = build_request(method_name, args, options)
          send_request(_request)
        end

        def delete(path, options = { })
          build_and_send_request(:delete, { :path => path }, options)
        end

        def get(path, options = { })
          build_and_send_request(:get, { :path => path }, options)
        end

        def head(path, options = { })
          build_and_send_request(:head, { :path => path }, options)
        end

        def options(path, options = { })
          build_and_send_request(:options, { :path => path }, options)
        end

        def put(path, body, options = { })
          build_and_send_request(:put, { :path => path, :body => body }, options)
        end

        def post(path, body, options = { })
          build_and_send_request(:post, { :path => path, :body => body }, options)
        end

        # HTTPClient
      end

      # Client
    end

    # API
  end

  # Vidispine
end