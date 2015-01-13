require 'vidispine/cli'
require 'vidispine/api/utilities/http_server'

module Vidispine

  module API

    class Utilities

      class HTTPServer

        class CLI < Vidispine::CLI

          def self.define_parameters
            default_http_host_address = Vidispine::API::Client::HTTPClient::DEFAULT_HTTP_HOST_ADDRESS
            default_http_host_port = Vidispine::API::Client::HTTPClient::DEFAULT_HTTP_HOST_PORT
            default_vidispine_username = Vidispine::API::Client::HTTPClient::DEFAULT_USERNAME
            default_vidispine_password = Vidispine::API::Client::HTTPClient::DEFAULT_PASSWORD

            argument_parser.on('--vidispine-http-host-address HOSTADDRESS', 'The address of the server to communicate with.', "\tdefault: #{default_http_host_address}") { |v| arguments[:http_host_address] = v }
            argument_parser.on('--vidispine-http-host-port HOSTPORT', 'The port to use when communicating with the server.', "\tdefault: #{default_http_host_port}") { |v| arguments[:http_host_port] = v }
            argument_parser.on('--vidispine-username USERNAME', 'The account username to authenticate with.', "\tdefault: #{default_vidispine_username}") { |v| arguments[:username] = v }
            argument_parser.on('--vidispine-password PASSWORD', 'The account password to authenticate with.', "\tdefault: #{default_vidispine_password}") { |v| arguments[:password] = v }

            argument_parser.on('--storage-path-map MAP', 'A path=>storage-id mapping to match incoming file paths to storages.') { |v| arguments[:storage_path_map] = v }
            argument_parser.on('--relative-file-path-collection-name-position NUM',
                'The relative position from the storage base path in which to select the collection name.',
                "\tdefault: 0") { |v| arguments[:relative_file_path_collection_name_position] = v }
            argument_parser.on('--metadata-file-path-field-id ID',
                               'The Id of the metadata field where the file path is to be stored.'
                              ) { |v| arguments[:metadata_file_path_field_id] = v }
            argument_parser.on('--bind-to-address ADDRESS', 'The local address to bind the server to.') { |v| arguments[:bind] = v }
            argument_parser.on('--port PORT', 'The port to bind to.', "\tdefault: 4567") { |v| arguments[:port] = v }
            argument_parser.on('--log-to FILENAME', 'Log file location.', "\tdefault: #{log_to_as_string}") { |v| arguments[:log_to] = v }
            argument_parser.on('--log-level LEVEL', LOGGING_LEVELS.keys, "Logging level. Available Options: #{LOGGING_LEVELS.keys.join(', ')}",
                               "\tdefault: #{LOGGING_LEVELS.invert[arguments[:log_level]]}") { |v| arguments[:log_level] = LOGGING_LEVELS[v] }

            argument_parser.on('--[no-]options-file [FILENAME]', 'Path to a file which contains default command line arguments.', "\tdefault: #{arguments[:options_file_path]}" ) { |v| arguments[:options_file_path] = v}
            argument_parser.on_tail('-h', '--help', 'Display this message.') { puts help; exit }
          end

          attr_accessor :logger, :api, :app

          def after_initialize
            arguments[:http_host_address] ||= '10.42.1.208'
            initialize_api(arguments)
            initialize_app(arguments)
          end

          def initialize_api(args = { })
            @api = Vidispine::API::Utilities.new(args)
          end

          def initialize_app(args = { })
            @app = Vidispine::API::Utilities::HTTPServer
            args_out = args
            args_out[:api] = api
            app.init(args)
          end

          def run(args = arguments, opts = options)
            app.run!
            self
          end

        end

      end

    end

  end

end
def cli; @cli ||= Vidispine::API::Utilities::HTTPServer::CLI end
