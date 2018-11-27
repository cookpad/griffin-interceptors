# frozen_string_literal: true

module Griffin
  module Interceptors
    module Server
      class ClearConnectionInterceptor < GRPC::ServerInterceptor
        def request_response(*)
          Rails.application.executor.wrap do
            ActiveRecord::Base.connection_pool.with_connection do
              yield
            end
          end
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response
      end
    end
  end
end
