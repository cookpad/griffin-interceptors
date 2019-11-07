# frozen_string_literal: true

require 'griffin/interceptors/server/payload_interceptor'

# Check actionpack exists to use ActionDispatch::Http::ParameterFilter if needed
gem 'actionpack' unless defined?(ActiveSupport::ParameterFilter)

module Griffin
  module Interceptors
    module Server
      class FilteredPayloadInterceptor < PayloadInterceptor
        def initialize(filter_parameters: [])
          @filters = filter_parameters.map do |filter|
            case filter
            when String, Symbol
              Regexp.new(filter.to_s, true)
            else
              filter
            end
          end

          # ActionDispatch::Http::ParameterFilter is deprecated and will be removed from Rails 6.1.
          parameter_filter_klass = if defined?(ActiveSupport::ParameterFilter)
              ActiveSupport::ParameterFilter
            else
              ActionDispatch::Http::ParameterFilter
            end
          @parameter_filter = parameter_filter_klass.new(@filters)
        end

        def server_streamer(call: nil, **)
          logs = {}

          if call.metadata['x-request-id']
            logs['grpc.x_request_id'] = call.metadata['x-request-id']
          end

          yield(Griffin::Interceptors::Server::PayloadStreamer.new(call, GRPC.logger, logs, @parameter_filter))
        end

        private

        def extract_content(request)
          @parameter_filter.filter(super)
        end
      end
    end
  end
end
