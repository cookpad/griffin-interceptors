# frozen_string_literal: true

gem 'scout_apm'

require 'scout_apm/layer'
require 'scout_apm/request_manager'

module Griffin
  module Interceptors
    module Server
      class ScoutApmInterceptor < GRPC::ServerInterceptor
        # Specify the controller layer so that the transaction gets categorized as a web transaction.
        LAYER_TYPE = 'Controller'

        def initialize(ignored_services: [], sampling_rate: 1.0)
          @ignored_services = ignored_services.map(&:service_name)
          @sampling_rate = sampling_rate.to_f
        end

        def request_response(request: nil, call: nil, method: nil)
          service_name = call.service_name
          method_name = method.name

          return yield if rand > @sampling_rate || @ignored_services.include?(service_name)

          layer = ScoutApm::Layer.new(LAYER_TYPE, "#{service_name}/#{method_name}")

          req = ScoutApm::RequestManager.lookup
          req.start_layer(layer)
          req.annotate_request(uri: "/#{service_name}/#{method_name}")

          ScoutApm::Context.add(
            request_id: call.metadata['x-request-id'],
            user_agent: call.metadata['user-agent'],
          )

          begin
            yield
          rescue => e
            req.error!
            raise e
          ensure
            req.stop_layer
          end
        end

        # For now, we don't support server_streamer, client_streamer and bidi_streamer
        # alias_method :server_streamer, :request_response
        # alias_method :client_streamer, :request_response
        # alias_method :bidi_streamer, :request_response
      end
    end
  end
end
