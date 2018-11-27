# frozen_string_literal: true

module Griffin
  module Interceptors
    module Server
      class PayloadStreamer
        # @param inner [GrpcKit::Calls::Call]
        # @param logger [Logger]
        # @param base_log [Hash<String,String>]
        def initialize(inner, logger, base_log = {}, filter = nil)
          @inner = inner
          @logger = logger
          @filter = filter
          @base_log = base_log
        end

        def send_msg(msg, **opts)
          @logger.info(@base_log.merge('grpc.response.content' => extract_content(msg)))
          @inner.send_msg(msg, **opts)
        end

        def recv(**opt)
          @inner.recv(**opt).tap do |req|
            @logger.info(@base_log.merge('grpc.request.content' => extract_content(req)))
          end
        end

        private

        def extract_content(request)
          if @filter
            @filter.filter(request.to_h)
          else
            request.to_h
          end
        end
      end
    end
  end
end
