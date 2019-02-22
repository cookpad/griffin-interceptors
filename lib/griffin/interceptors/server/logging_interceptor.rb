# frozen_string_literal: true

module Griffin
  module Interceptors
    module Server
      class LoggingInterceptor < GRPC::ServerInterceptor
        def request_response(call: nil, **)
          now = Time.now
          log = build_log(call, now)

          resp =
            begin
              yield
            rescue => e
              if e.is_a?(GRPC::BadStatus)
                log['grpc.code'] = e.code
              else
                log['grpc.code'] = '2' # UNKNOWN
              end

              log['grpc.duration'] = (Time.now - now).to_s
              GRPC.logger.info(log)
              raise e
            end

          log['grpc.duration'] = (Time.now - now).to_s
          GRPC.logger.info(log)
          resp
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response

        private

        # @return [Hash<String,String>]
        def build_log(call, start_time)
          log = {
            'system' => 'grpc',
            'span.kind' => 'server',
            'grpc.method' => call.method_name,
            'grpc.service_name' => call.service_name,
            'grpc.start_time' => start_time.to_s,
            'grpc.code' => '0', # OK
          }

          if call.metadata['x-request-id']
            log['grpc.x_request_id'] = call.metadata['x-request-id']
          end

          if call.deadline
            log['grpc.request.deadline'] = call.deadline
          end

          log
        end
      end
    end
  end
end
