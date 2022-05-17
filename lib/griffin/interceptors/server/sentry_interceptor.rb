# frozen_string_literal: true

gem "sentry-ruby"

module Griffin
  module Interceptors
    module Server
      class SentryInterceptor < GRPC::ServerInterceptor
        TRANSACTION_OP = "griffin"

        def request_response(request: nil, call: nil, method: nil)
          return yield unless Sentry.initialized?

          Sentry.clone_hub_to_current_thread

          Sentry.with_scope do |scope|
            Sentry.with_session_tracking do
              scope.clear_breadcrumbs

              service_name = call.service_name
              method_name = method.name
              scope.set_transaction_name("#{service_name}/#{method_name}")

              transaction = start_transaction(call.metadata, scope)
              scope.set_span(transaction) if transaction

              if call.metadata["x-request-id"]
                scope.set_tags(request_id: call.metadata["x-request-id"])
              end

              begin
                response = yield
              rescue => e
                if e.is_a?(GRPC::BadStatus)
                  finish_transaction(transaction, e.code)
                  raise e
                end

                GRPC.logger.error("Internal server error: #{e}")
                finish_transaction(transaction, GrpcKit::StatusCodes::INTERNAL)
                Sentry.capture_exception(e)

                raise GRPC::Unknown.new("Internal server error")
              end

              finish_transaction(transaction, GrpcKit::StatusCodes::OK)

              response
            end
          end
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response

        private

        def start_transaction(metadata, scope)
          sentry_trace = metadata["grpc-sentry-trace"]
          options = { name: scope.transaction_name, op: TRANSACTION_OP }
          transaction = Sentry::Transaction.from_sentry_trace(sentry_trace, **options) if sentry_trace
          Sentry.start_transaction(transaction: transaction, custom_sampling_context: { metadata: metadata }, **options)
        end

        def finish_transaction(transaction, status_code)
          return unless transaction

          transaction.set_http_status(status_code)
          transaction.finish
        end
      end
    end
  end
end
