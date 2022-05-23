# frozen_string_literal: true

module Griffin
  module Interceptors
    module Server
      class RailsExceptionInterceptor < GRPC::ServerInterceptor
        def request_response(*)
          begin
            yield
          rescue ActiveRecord::RecordNotFound => e
            capture_exception_if_defined(e)
            raise GRPC::NotFound.new(e.message)
          rescue ActiveRecord::StaleObjectError => e
            capture_exception_if_defined(e)
            raise GRPC::Aborted.new(e.message)
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
            capture_exception_if_defined(e)
            raise GRPC::FailedPrecondition.new(e.message)
          end
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response

        private

        def capture_exception_if_defined(e)
          if defined?(Sentry)
            Sentry.capture_exception(e)
          elsif defined?(Raven)
            Raven.capture_exception(e)
          end
        end
      end
    end
  end
end
