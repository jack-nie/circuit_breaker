module CircuitBreaker
  class Open < StandardError; end

  class CircuitHandler
    attr_accessor :invocation_timeout, :failure_threshold
    def initialize &block
      @circuit = block
      @invocation_timeout = 2
      @failure_threshold = 5
      @monitor = CircuitBreaker::BreakerMonitor.new
      @reset_timeout = 0.1
      reset
    end

    def call args
      case state
      when :closed, :half_open
        begin
          do_call args
        rescue Timeout::Error
          record_failure
          raise $!
        end
      when :open
        raise CircuitBreaker::Open
      else
        raise "Unreachable Code"
      end
    end

    def do_call args
      result = Timeout::timeout(@invocation_timeout) do
        @circuit.call args
      end
      reset
      result
    end

    def record_failure
      @failure_count += 1
      @last_failure_time = Time.now
      @monitor.alert(:open_circuit) if state == :open
    end

    def reset
      @failure_count = 0
      @last_failure_time = nil
      @monitor.alert :reset_circuit
    end

    def state
      case
      when (@failure_count >= @failure_threshold) &&
        (Time.now - @last_failure_time) > @reset_timeout
        :half_open
      when (@failure_count >= @failure_threshold)
        :open
      else
        :closed
      end
    end
  end
end
