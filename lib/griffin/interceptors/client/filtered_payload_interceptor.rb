# frozen_string_literal: true

require 'griffin/interceptors/client/payload_interceptor'

# Check actionpack exists to use ActionDispatch::Http::ParameterFilter
gem 'actionpack'

module Griffin
  module Interceptors
    module Client
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

          @parameter_filter = ActionDispatch::Http::ParameterFilter.new(@filters)
        end

        def server_streamer(call: nil, **)
          logs = {}

          if call.metadata['x-request-id']
            logs['grpc.x_request_id'] = call.metadata['x-request-id']
          end

          yield(Griffin::Interceptors::Client::PayloadStreamer.new(call, GRPC.logger, logs, @parameter_filter))
        end

        private

        def extract_content(request)
          @parameter_filter.filter(super)
        end
      end
    end
  end
end
