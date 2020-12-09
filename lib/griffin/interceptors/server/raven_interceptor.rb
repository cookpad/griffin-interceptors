# frozen_string_literal: true

gem 'sentry-raven'

module Griffin
  module Interceptors
    module Server
      class RavenInterceptor < GRPC::ServerInterceptor
        def request_response(call: nil, **)
          if call.metadata['x-request-id']
            Raven.tags_context(request_id: call.metadata['x-request-id'])
          end

          begin
            yield
          rescue => e
            raise e if e.is_a?(GRPC::BadStatus)

            GRPC.logger.error("Internal server error: #{e.message}")
            Raven.capture_exception(e)

            raise GRPC::Unknown.new('Internal server error')
          end
        ensure
          Raven::Context.clear!
          Raven::BreadcrumbBuffer.clear!
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response
      end
    end
  end
end
