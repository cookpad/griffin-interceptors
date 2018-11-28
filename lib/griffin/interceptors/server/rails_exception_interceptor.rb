# frozen_string_literal: true

gem 'sentry-raven'

module Griffin
  module Interceptors
    module Server
      class RailsExceptionInterceptor < GRPC::ServerInterceptor
        def request_response(*)
          begin
            yield
          rescue ActiveRecord::RecordNotFound => e
            Raven.capture_exception(e)
            raise GRPC::NotFound.new(e.message)
          rescue ActiveRecord::StaleObjectError => e
            Raven.capture_exception(e)
            raise GRPC::Aborted.new(e.message)
          rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
            Raven.capture_exception(e)
            raise GRPC::FailedPrecondition.new(e.message)
          end
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response
      end
    end
  end
end
