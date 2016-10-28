require "logger"
module CircuitBreaker
  class BreakerMonitor

    def alert(msg)
      Logger.new(STDOUT).warn msg
    end

  end
end
