# frozen_string_literal: true

require 'griffin/interceptors/server/payload_streamer'

module Griffin
  module Interceptors
    module Server
      class PayloadInterceptor < GRPC::ServerInterceptor
        def request_response(request: nil, call: nil, **)
          logs = {}

          if call.metadata['x-request-id']
            logs['grpc.x_request_id'] = call.metadata['x-request-id']
          end

          GRPC.logger.info(logs.merge('grpc.request.content' => extract_content(request)))

          yield.tap do |resp|
            logs['grpc.response.content'] = extract_content(resp)
            GRPC.logger.info(logs)
          end
        end

        def server_streamer(call: nil, **)
          logs = {}

          if call.metadata['x-request-id']
            logs['grpc.x_request_id'] = call.metadata['x-request-id']
          end

          yield(Griffin::Interceptors::Server::PayloadStreamer.new(call, GRPC.logger, logs))
        end

        alias_method :client_streamer, :server_streamer
        alias_method :bidi_streamer, :server_streamer

        private

        def extract_content(msg)
          msg.to_h
        end
      end
    end
  end
end
