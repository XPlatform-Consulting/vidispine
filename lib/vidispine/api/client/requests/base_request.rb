require 'cgi'
require 'uri'

module Vidispine
  module API
    class Client
      module Requests

        class BaseRequest

          HTTP_METHOD = :get
          HTTP_BASE_PATH = '/API/' # Not used, using client.api_endpoint_prefix instead
          HTTP_PATH = ''
          HTTP_SUCCESS_CODE = '200'

          DEFAULT_PARAMETER_SEND_IN_VALUE = :query

          PARAMETERS = [ ]

          attr_accessor :client, :arguments, :options, :initial_arguments, :missing_required_arguments,
                        :default_parameter_send_in_value, :processed_parameters

          attr_writer :parameters, :path, :body, :query

          def self.normalize_argument_hash_keys(hash)
            return hash unless hash.is_a?(Hash)
            Hash[ hash.dup.map { |k,v| [ normalize_parameter_name(k), v ] } ]
          end

          def self.normalize_parameter_name(name)
            (name || '').respond_to?(:to_s) ? name.to_s.gsub('_', '').gsub('-', '').downcase : name
          end

          def self.process_parameters(params, args, options = { })
            args = normalize_argument_hash_keys(args) || { }
            args_out = options[:arguments_out] || { }
            default_parameter_send_in_value = options[:default_parameter_send_in_value] || DEFAULT_PARAMETER_SEND_IN_VALUE
            processed_parameters = options[:processed_parameters] || { }
            missing_required_arguments = options[:missing_required_arguments] || [ ]

            params.each do |param|
              process_parameter(param, args, args_out, missing_required_arguments, processed_parameters, default_parameter_send_in_value)
            end
            { :arguments_out => args_out, :processed_parameters => processed_parameters, :missing_required_arguments => missing_required_arguments }
          end

          # A method to expose parameter processing
          #
          # @param [Hash|Symbol] param The parameter to process
          # @param [Hash] args ({ }) Arguments to possibly match to the parameter
          # @param [Hash] args_out ({ }) The processed value of the parameter (if any)
          # @param [Array] missing_required_arguments ([ ]) If the parameter was required and no argument found then it
          # will be placed into this array
          # @param [Hash] processed_parameters ({ }) The parameter will be placed into this array once processed
          # @param [Symbol] default_parameter_send_in_value (DEFAULT_PARAMETER_SEND_IN_VALUE) The :send_in value that
          # will be set if the :send_in key is not found
          # @param [Hash] options
          # @option options [True|False] :normalize_argument_hash_keys (false)
          def self.process_parameter(param, args = { }, args_out = { }, missing_required_arguments = [ ], processed_parameters = { }, default_parameter_send_in_value = DEFAULT_PARAMETER_SEND_IN_VALUE, options = { })
            args = normalize_argument_hash_keys(args) || { } if options.fetch(:normalize_argument_hash_keys, false)

            _k = param.is_a?(Hash) ? param : { :name => param, :required => false, :send_in => default_parameter_send_in_value }
            _k[:send_in] ||= default_parameter_send_in_value

            proper_parameter_name = _k[:name]
            param_name = normalize_parameter_name(proper_parameter_name)
            arg_key = (has_key = args.has_key?(param_name)) ?
                param_name :
                ( (_k[:aliases] || [ ]).map { |a| normalize_parameter_name(a) }.find { |a| has_key = args.has_key?(a) } || param_name )

            value = has_key ? args[arg_key] : _k[:default_value]
            is_set = has_key || _k.has_key?(:default_value)

            processed_parameters[proper_parameter_name] = _k.merge(:value => value, :is_set => is_set)

            unless is_set
              missing_required_arguments << proper_parameter_name if _k[:required]
            else
              args_out[proper_parameter_name] = value
            end

            { :arguments_out => args_out, :processed_parameters => processed_parameters, :missing_required_arguments => missing_required_arguments }
          end

          def initialize(args = { }, options = { })
            @initial_arguments = args.dup
            @options = options.dup

            after_initialize
          end

          def after_initialize
            reset_attributes

            process_parameters
          end

          def reset_attributes
            @client = options[:client]
            @missing_required_arguments = [ ]
            @default_parameter_send_in_value = options[:default_parameter_send_in_value] || self.class::DEFAULT_PARAMETER_SEND_IN_VALUE
            @processed_parameters = { }
            @arguments = { }
            @eval_http_path = options.fetch(:eval_http_path, true)
            @base_path = options[:base_path]

            @parameters = options[:parameters]
            @http_method = options[:http_method]
            @http_path = options[:http_path] ||= options[:path_raw]
            @http_success_code = options[:http_success_code] ||= HTTP_SUCCESS_CODE

            @path = options[:path]
            @path_arguments = nil
            @path_only = nil

            @matrix = options[:matrix]
            @matrix_arguments = nil

            @query = options[:query]
            @query_arguments = nil

            @body = options[:body]
            @body_arguments = nil
          end

          def process_parameters(params = parameters, args = @initial_arguments, options = @options)

            before_process_parameters unless options.fetch(:skip_before_process_parameters, false)
            self.class.process_parameters(params, args, options.merge(:processed_parameters => processed_parameters, :missing_required_arguments => missing_required_arguments, :default_parameter_send_in_value => default_parameter_send_in_value, :arguments_out => arguments))
            after_process_parameters unless options.fetch(:skip_after_process_parameters, false)

          end

          def before_process_parameters
            # TO BE IMPLEMENTED IN CHILD CLASS
          end

          def after_process_parameters
            # TO BE IMPLEMENTED IN CHILD CLASS
          end

          # @!group Attribute Readers

          def http_success_code
            @http_success_code
          end

          def arguments
            @arguments ||= { }
          end

          def base_path
            @base_path ||= client.api_endpoint_prefix # self.class::HTTP_BASE_PATH
          end

          def body_arguments
            @body_arguments ||= arguments.dup.delete_if { |k,_| processed_parameters[k][:send_in] != :body }
          end

          def body
            body_arguments.empty? ? nil : body_arguments
          end

          def client
            @client ||= options[:client]
          end

          def eval_http_path?
            @eval_http_path
          end

          def http_path
            @http_path ||= self.class::HTTP_PATH #||= File.join(http.default_base_path, self.class::HTTP_PATH)
          end

          def http_method
            @http_method ||= self.class::HTTP_METHOD
          end

          def parameters
            @parameters ||= self.class::PARAMETERS.dup
          end

          # The URI Path including "matrix" arguments
          def path
            @path ||= [ path_only ].concat( [*matrix].delete_if { |v| v.respond_to?(:empty?) and v.empty? } ).join('')
          end
          alias :path_with_matrix :path

          def path_arguments
            @path_arguments ||= Hash[
                arguments.dup.delete_if { |k, _| processed_parameters[k][:send_in] != :path }.
                    map { |k,v| [ k, CGI.escape(v.respond_to?(:to_s) ? v.to_s : '').gsub('+', '%20') ] }
            ]
          end

          def path_only
            @path_only ||= File.join(base_path, (eval_http_path? ? eval(%("#{http_path}"), binding, __FILE__, __LINE__) : http_path))
          end

          def query
            @query ||= begin
              query_arguments.is_a?(Hash) ? query_arguments.map { |k,v| "#{CGI.escape(k.to_s).gsub('+', '%20')}=#{CGI.escape(v.respond_to?(:to_s) ? v.to_s : v).gsub('+', '%20')}" }.join('&') : query_arguments
            end
          end

          def query_arguments
            @query_arguments ||= arguments.dup.delete_if { |k,_| processed_parameters[k][:send_in] != :query }
          end

          def matrix
            @matrix = matrix_arguments.map { |k,v| ";#{CGI.escape(k.to_s).gsub('+', '%20')}=#{CGI.escape(v.to_s).gsub('+', '%20')}" }.join('')
          end

          def matrix_arguments
            @matrix_arguments ||= arguments.dup.delete_if { |k,_| processed_parameters[k][:send_in] != :matrix }
          end

          def uri_request_path
            [ path_with_matrix ].concat( [*query].delete_if { |v| v.respond_to?(:empty?) and v.empty? } ).join('?')
          end

          def success?
            _response = client.http_client.response
            _response && (_response.code == http_success_code)
          end

          # @!endgroup

        end
      end
    end
  end
end
