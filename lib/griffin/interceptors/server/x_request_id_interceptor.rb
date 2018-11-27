# frozen_string_literal: true

require 'securerandom'

module Griffin
  module Interceptors
    module Server
      class XRequestIdInterceptor < GRPC::ServerInterceptor
        KEY = 'x-request-id'

        def request_response(call: nil, **)
          unless call.metadata[KEY]
            call.metadata[KEY] = SecureRandom.uuid
          end

          yield
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response
      end
    end
  end
end
