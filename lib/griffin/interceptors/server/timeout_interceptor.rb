# frozen_string_literal: true

require 'timeout'

module Griffin
  module Interceptors
    module Server
      class TimeoutInterceptor < GRPC::ServerInterceptor
        DEFAULT_TIMEOUT = 5

        def initialize(timeout = DEFAULT_TIMEOUT)
          @timeout = timeout
        end

        def request_response(*)
          Timeout.timeout(@timeout) do
            yield
          end
        end

        # For now, we don't support server_streamer, client_streamer and bidi_streamer
      end
    end
  end
end
