# frozen_string_literal: true

gem 'newrelic_rpm'

module Griffin
  module Interceptors
    module Server
      class NewRelicInterceptor < GRPC::ServerInterceptor
        def initialize(ignored_services: [])
          @ignored_services = ignored_services.map(&:service_name)
        end

        Request = Struct.new(:path, :user_agent, :request_method)

        def request_response(method: nil, call: nil, **)
          return yield unless NewRelic::Agent.instance.started?

          service_name = call.service_name

          return yield if @ignored_services.include?(service_name)

          transaction_name = build_transaction_name(service_name, method.name)
          state = NewRelic::Agent::TransactionState.tl_get

          # gRPC's HTTP method is fixed. https://github.com/grpc/grpc/blob/af89e8c00e796f3398b09b7daed693df2b14da56/doc/PROTOCOL-HTTP2.md
          req = Request.new("/#{transaction_name}", call.metadata['user-agent'], 'POST')
          # ":controller" is not correct category name for gRPC, But since we want to categorized this transaction as web transactions.
          # https://docs.newrelic.com/docs/apm/transactions/key-transactions/introduction-key-transactions
          NewRelic::Agent::Transaction.start(state, :controller, transaction_name: "Controller/#{transaction_name}", request: req)

          begin
            yield
            # gRPC alway returns HTTP status code 200
            state.current_transaction.http_response_code = '200'
          rescue => e
            NewRelic::Agent::Transaction.notice_error(e)
            raise e
          ensure
            NewRelic::Agent::Transaction.stop(state)
          end
        end

        # For now, we don't support server_streamer, client_streamer and bidi_streamer

        private

        def build_transaction_name(service, mthd)
          "#{service}/#{mthd}"
        end
      end
    end
  end
end
