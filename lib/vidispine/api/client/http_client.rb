require 'json'
require 'net/http'

module Vidispine
  module API
    class Client

      class HTTPClient

        class HTTPAuthorizationError < RuntimeError; end

        attr_accessor :logger, :http, :http_host_address, :http_host_port, :base_uri
        attr_accessor :username, :password

        attr_accessor :default_request_headers,
                      :authorization_header_key, :authorization_header_value

        attr_accessor :log_request_body, :log_response_body, :log_pretty_print_body

        attr_accessor :request, :response, :use_exceptions

        DEFAULT_HTTP_HOST_ADDRESS = 'localhost'
        DEFAULT_HTTP_HOST_PORT = 8080

        DEFAULT_USERNAME = 'admin'
        DEFAULT_PASSWORD = 'password'
        DEFAULT_BASE_PATH = '/API/'

        DEFAULT_HEADER_CONTENT_TYPE = 'application/json; charset=utf-8'
        DEFAULT_HEADER_ACCEPTS = 'application/json'

        def initialize(args = { })
          args = args.dup

          @use_exceptions = args.fetch(:use_exceptions, true)

          initialize_logger(args)
          initialize_http(args)

          logger.debug { "#{self.class.name}::#{__method__} Arguments: #{args.inspect}" }

          @username = args[:username] || DEFAULT_USERNAME
          @password = args[:password] || DEFAULT_PASSWORD

          @base_uri = args[:base_uri] || "http#{http.use_ssl? ? 's' : ''}://#{http.address}:#{http.port}"
          @default_base_path = args[:default_base_path] || DEFAULT_BASE_PATH

          # @user_agent_default = "#{@hostname}:#{@username} Ruby SDK Version #{Vidispine::VERSION}"

          @authorization_header_key ||= 'Authorization' #CaseSensitiveHeaderKey.new('Authorization')
          @authorization_header_value ||= %(Basic #{["#{username}:#{password}"].pack('m').delete("\r\n")})

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
            # @TODO Add SSL Support
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

        # @param [String] path
        # @param [Hash|String|Nil] query
        # @return [URI]
        def build_uri(path = '', query = nil)
          _query = query.is_a?(Hash) ? query.map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.respond_to?(:to_s) ? v.to_s : v)}" }.join('&') : query
          _path = "#{path}#{_query and _query.respond_to?(:empty?) and !_query.empty? ? "?#{_query}" : ''}"
          URI.parse(File.join(base_uri, _path))
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

        # @param [Symbol] method_name (:get)
        # @param [Hash] args
        # @option args [Hash] :headers ({})
        # @option args [String] :path ('')
        # @option args [Hash] :query ({})
        # @option args [Any] :body (nil)
        # @param [Hash] options
        # @option options [Hash] :default_request_headers (@default_request_headers)
        def call_method(method_name = :get, args = { }, options = { })
          headers = args[:headers] || options[:headers] || { }
          path = args[:path] || ''
          query = args[:query] || { }
          body = args[:body]

          # Allow the default request headers to be overridden
          _default_request_headers = options.fetch(:default_request_headers, default_request_headers)
          _default_request_headers ||= { }
          _headers = _default_request_headers.merge(headers)

          @uri = build_uri(path, query)
          klass_name = request_method_name_to_class_name(method_name)
          klass = Net::HTTP.const_get(klass_name)

          request = klass.new(@uri.request_uri, _headers)

          if request.request_body_permitted?
            _body = (body and !body.is_a?(String)) ? JSON.generate(body) : body
            logger.debug { "Processing Body: '#{_body}'" }
            request.body = _body if _body
          end

          send_request(request)
        end

        def delete(path, options = { })
          query = options.fetch(:query, { })
          base_path = options[:base_path] || ( path.start_with?('/API') ? '' : @default_base_path )
          @uri = build_uri(File.join(base_path, path), query)
          request = Net::HTTP::Delete.new(@uri.request_uri, default_request_headers)
          send_request(request)
        end

        def get(path, options = { })
          # Allow the default request headers to be overridden
          headers = options[:headers] || { }
          _default_request_headers = options.fetch(:default_request_headers, default_request_headers) || { }
          _headers = _default_request_headers.merge(headers)

          query ||= options.fetch(:query, { })
          base_path = options[:base_path] || ( path.start_with?('/API') ? '' : @default_base_path )
          @uri = build_uri(File.join(base_path, path), query)
          request = Net::HTTP::Get.new(@uri.request_uri, _headers)
          send_request(request)
        end

        def head(path, options = { })
          # Allow the default request headers to be overridden
          headers = options[:headers] || { }
          _default_request_headers = options.fetch(:default_request_headers, default_request_headers) || { }
          _headers = _default_request_headers.merge(headers)

          query ||= options.fetch(:query, { })
          base_path = options[:base_path] || ( path.start_with?('/API') ? '' : @default_base_path )
          @uri = build_uri(File.join(base_path, path), query)

          request = Net::HTTP::Head.new(@uri.request_uri, _headers)
          send_request(request)
        end

        def options(path, options = { })
          # Allow the default request headers to be overridden
          headers = options[:headers] || { }
          _default_request_headers = options.fetch(:default_request_headers, default_request_headers) || { }
          _headers = _default_request_headers.merge(headers)

          query ||= options.fetch(:query, { })
          base_path = options[:base_path] || ( path.start_with?('/API') ? '' : @default_base_path )
          @uri = build_uri(File.join(base_path, path), query)
          request = Net::HTTP::Options.new(@uri.request_uri, _headers)
          send_request(request)
        end

        def put(path, body, options = { })
          # Allow the default request headers to be overridden
          headers = options[:headers] || { }
          _default_request_headers = options.fetch(:default_request_headers, default_request_headers) || { }
          _headers = _default_request_headers.merge(headers)

          query = options.fetch(:query, { })
          base_path = options[:base_path] || ( path.start_with?('/API') ? '' : @default_base_path )
          @uri = build_uri(File.join(base_path, path), query)
          request = Net::HTTP::Put.new(@uri.request_uri, _headers)

          body = JSON.generate(body) if body and !body.is_a?(String)

          request.body = body if body
          send_request(request)
        end

        def post(path, body, options = { })
          # Allow the default request headers to be overridden
          headers = options[:headers] || { }
          _default_request_headers = options.fetch(:default_request_headers, default_request_headers) || { }
          _headers = _default_request_headers.merge(headers)

          query = options.fetch(:query, { })
          base_path = options[:base_path] || ( path.start_with?('/API') ? '' : @default_base_path )
          @uri = build_uri(File.join(base_path, path), query)

          request = Net::HTTP::Post.new(@uri.request_uri, _headers)

          body = JSON.generate(body) if body and !body.is_a?(String)

          request.body = body if body
          send_request(request)
        end

        # HTTPClient
      end

      # Client
    end

    # API
  end

  # Vidispine
end