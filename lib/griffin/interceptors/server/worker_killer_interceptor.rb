# frozen_string_literal: true

require 'get_process_mem'

module Griffin
  module Interceptors
    module Server
      class WorkerKillerInterceptor < GRPC::ServerInterceptor
        def initialize(memory_limit_min: 1024**3, memory_limit_max: 2 * (1024**3), check_cycle: 16)
          @worker_memory_limit_max = memory_limit_max
          @worker_memory_limit_min = memory_limit_min
          @worker_check_cycle = check_cycle
          @worker_memory_limit = @worker_memory_limit_min + rand(@worker_memory_limit_max - @worker_memory_limit_min + 1)
          @worker_check_count = 0
          @sent_signals = false
        end

        def request_response(*)
          yield.tap do
            break if @sent_signals

            @worker_process_start ||= Time.now
            @worker_check_count += 1

            if (@worker_check_count % @worker_check_cycle) == 0
              rss = GetProcessMem.new.bytes
              if rss > @worker_memory_limit
                Griffin.logger.warn("Worker (pid: #{Process.pid}) exceeds memory limit (#{rss.to_f} bytes > #{@worker_memory_limit} bytes)")
                send_restart_signal(@worker_process_start)
              end

              @worker_check_count = 0
            end
          end
        end

        alias_method :server_streamer, :request_response
        alias_method :client_streamer, :request_response
        alias_method :bidi_streamer, :request_response

        private

        def send_restart_signal(start_time)
          # No need to get a lock, sending signals duplicately is acceptable
          @sent_signals = true
          pid = Process.pid
          alive_sec = (Time.now - start_time).round

          Griffin.logger.info("Send signal(USR1) pid: #{pid}, alive_sec: #{alive_sec}")
          Process.kill :USR1, pid
        end
      end
    end
  end
end
