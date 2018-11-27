# frozen_string_literal: true

require 'securerandom'

module Griffin
  module Interceptors
    module Client
      class XRequestIdInterceptor < GRPC::ClientInterceptor
        KEY = 'x-request-id'

        def request_response(call: nil, **)
          call.metadata[KEY] = SecureRandom.uuid
          yield
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response
      end
    end
  end
end
