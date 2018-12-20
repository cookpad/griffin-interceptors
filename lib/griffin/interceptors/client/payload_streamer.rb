# frozen_string_literal: true

require 'griffin/interceptors/call_stream'

module Griffin
  module Interceptors
    module Client
      class PayloadStreamer
        # @param inner [GrpcKit::Calls::Call]
        # @param logger [Logger]
        # @param base_log [Hash<String,String>]
        def initialize(inner, logger, base_log = {}, filter = nil)
          super(inner)
          @logger = logger
          @filter = filter
          @base_log = base_log
        end

        def send_msg(msg)
          @logger.info(@base_log.merge('grpc.request.content' => extract_content(msg)))
          super
        end

        def recv
          super.tap do |resp|
            @logger.info(@base_log.merge('grpc.response.content' => extract_content(resp)))
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
