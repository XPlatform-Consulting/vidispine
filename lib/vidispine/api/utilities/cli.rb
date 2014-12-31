require 'json'
require 'pp'
require 'rexml/document'

require 'vidispine/cli'
require 'vidispine/api/utilities'

module Vidispine

  module API

    class Utilities

      class CLI < Vidispine::CLI

        def self.define_parameters
          default_http_host_address = Vidispine::API::Client::HTTPClient::DEFAULT_HTTP_HOST_ADDRESS
          default_http_host_port = Vidispine::API::Client::HTTPClient::DEFAULT_HTTP_HOST_PORT
          default_accepts_header = Vidispine::API::Client::HTTPClient::DEFAULT_HEADER_ACCEPTS
          default_content_type_header = Vidispine::API::Client::HTTPClient::DEFAULT_HEADER_CONTENT_TYPE

          argument_parser.on('--host-address HOSTADDRESS', 'The address of the server to communicate with.', "\tdefault: #{default_http_host_address}") { |v| arguments[:http_host_address] = v }
          argument_parser.on('--host-port HOSTPORT', 'The port to use when communicating with the server.', "\tdefault: #{default_http_host_port}") { |v| arguments[:http_host_port] = v }
          argument_parser.on('--username USERNAME', 'The account username to authenticate with.') { |v| arguments[:username] = v }
          argument_parser.on('--password PASSWORD', 'The account password to authenticate with.') { |v| arguments[:password] = v }

          argument_parser.on('--accept-header VALUE', 'The value for the Accept header sent in each request.', "\tdefault: #{default_accepts_header}") { |v| arguments[:accepts_header] = v }
          argument_parser.on('--content-type VALUE', 'The value for the Content-Type header sent in each request.', "\tdefault: #{default_content_type_header}") { |v| arguments[:content_type] = v }
          argument_parser.on('--method-name METHODNAME', 'The name of the method to call.') { |v| arguments[:method_name] = v }
          argument_parser.on('--method-arguments JSON', 'The arguments to pass when calling the method.') { |v| arguments[:method_arguments] = v }
          argument_parser.on('--pretty-print', 'Will format the output to be more human readable.') { |v| arguments[:pretty_print] = v }

          argument_parser.on('--log-to FILENAME', 'Log file location.', "\tdefault: #{log_to_as_string}") { |v| arguments[:log_to] = v }
          argument_parser.on('--log-level LEVEL', LOGGING_LEVELS.keys, "Logging level. Available Options: #{LOGGING_LEVELS.keys.join(', ')}",
                "\tdefault: #{LOGGING_LEVELS.invert[arguments[:log_level]]}") { |v| arguments[:log_level] = LOGGING_LEVELS[v] }

          argument_parser.on('--[no-]options-file [FILENAME]', 'Path to a file which contains default command line arguments.', "\tdefault: #{arguments[:options_file_path]}" ) { |v| arguments[:options_file_path] = v}
          argument_parser.on_tail('-h', '--help', 'Display this message.') { puts help; exit }
        end

        attr_accessor :logger, :api

        def after_initialize
          initialize_api(arguments)
        end

        def initialize_api(args = { })
          @api = Vidispine::API::Utilities.new(args )
        end

        def run(args = arguments, opts = options)
          method_name = args[:method_name]
          send(method_name, args[:method_arguments], :pretty_print => args[:pretty_print]) if method_name

          self
        end

        def send(method_name, method_arguments, params = {})
          method_name = method_name.to_sym
          logger.debug { "Executing Method: #{method_name}" }

          send_arguments = [ method_name ]

          if method_arguments
            method_arguments = JSON.parse(method_arguments, :symbolize_names => true) if method_arguments.is_a?(String) and method_arguments.start_with?('{', '[')
            send_arguments.concat  method_arguments.is_a?(Array) ? [ *method_arguments ] : [ method_arguments ]
          end
          #puts "Send Arguments: #{send_arguments.inspect}"
          response = api.__send__(*send_arguments)

          # if response.code.to_i.between?(500,599)
          #   puts parsed_response
          #   exit
          # end
          #
          # if ResponseHandler.respond_to?(method_name)
          #   ResponseHandler.client = api
          #   ResponseHandler.response = response
          #   response = ResponseHandler.__send__(*send_arguments)
          # end

          if params[:pretty_print]
            if response.is_a?(String)
              _response_cleaned = response.strip
              if _response_cleaned.start_with?('{', '[')
                puts prettify_json(response)
              elsif _response_cleaned.start_with?('<') and _response_cleaned.end_with?('>')
                puts prettify_xml(response)
              else
                pp response
              end
            else
              pp response
            end
          else
            response = JSON.generate(response) if response.is_a?(Hash) or response.is_a?(Array)
            puts response
          end
          # send
        end


        def prettify_json(json)
          JSON.pretty_generate(JSON.parse(json))
        end

        def prettify_xml(xml, options = { })
          document = REXML::Document.new(xml)
          document.write(output = '', options[:indent] || 1)

          return output unless options.fetch(:collapse_tags, true)

          last_open_tag = ''
          #last_matching_close_tag = ''
          last_was_tag = false
          last_was_matching_close_tag = false

          output.lines.map do |v|
            _v = v.strip

            is_tag = _v.start_with?('<') and _v.end_with?('>')
            is_open_tag = (is_tag and !_v.start_with?('</'))
            is_matching_close_tag = (is_tag and !is_open_tag and _v == "</#{(last_open_tag || '')[1..-1]}")

            _output = if is_open_tag
                        "#{(last_was_tag and !last_was_matching_close_tag) ? "\n" : ''}#{v.rstrip}"
                      elsif is_matching_close_tag
                        "#{_v}\n"
                      elsif !is_tag
                        _v
                      else
                        v
                      end
            #puts "V: '#{_v}' IT: #{is_tag} IOT: #{is_open_tag} ICT: #{is_matching_close_tag} LOT: '#{last_open_tag}' LCT: #{last_matching_close_tag} OUTPUT: '#{_output}'"

            last_was_tag = is_tag
            last_was_matching_close_tag = is_matching_close_tag
            if is_open_tag
              last_open_tag = _v.split(' ').first
              last_open_tag << '>' unless last_open_tag.end_with?('>')
            elsif is_matching_close_tag
              #last_matching_close_tag = _v
            end

            _output
          end.join('')
        end

        # CLI
      end

      # Utilities
    end

    # API
  end

  # Vidispine
end
def cli; @cli ||= Vidispine::API::Utilities::CLI end
