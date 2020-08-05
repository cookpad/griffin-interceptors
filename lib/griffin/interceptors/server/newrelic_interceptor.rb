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

          # gRPC's HTTP method is fixed. https://github.com/grpc/grpc/blob/af89e8c00e796f3398b09b7daed693df2b14da56/doc/PROTOCOL-HTTP2.md
          request = Request.new("/#{service_name}/#{method.name}", call.metadata['user-agent'], 'POST')

          in_transaction("#{service_name}/#{method.name}", request) do |txn|
            yield.tap do
              # gRPC always returns HTTP status code 200.
              txn.http_response_code = '200'
            end
          end
        end

        # For now, we don't support server_streamer, client_streamer and bidi_streamer

        private

        if Gem::Version.new(NewRelic::VERSION::STRING) >= Gem::Version.new('6.0.0')
          def in_transaction(partial_name, request)
            NewRelic::Agent::Tracer.in_transaction(partial_name: partial_name, category: :web, options: { request: request }) do
              yield NewRelic::Agent::Tracer.current_transaction
            end
          end
        else
          def in_transaction(partial_name, request)
            state = NewRelic::Agent::TransactionState.tl_get
            # Specify the controller category so that the transaction gets categorized as a web transaction.
            # See https://github.com/newrelic/newrelic-ruby-agent/blob/5.7.0.350/lib/new_relic/agent/transaction.rb#L39.
            NewRelic::Agent::Transaction.wrap(state, "Controller/#{partial_name}", :controller, request: request) do
              yield state.current_transaction
            end
          end
        end
      end
    end
  end
end
