class ShortCircuit
  class NoActionSpecifiedError < StandardError; end

  def self.on(signal, &blk)
    self.new(signal, &blk)
  end

  def initialize(signal_name, &sc_blk)
    if sc_blk.nil?
      raise ::ShortCircuit::NoActionSpecifiedError.new("You must specify a short circuit action.")
    end
    @signal_name = signal_name
    @short_circuit_action = sc_blk
    @procs = []
  end

  def and_then(&blk)
    @procs << blk
    self
  end

  def call(value)
    failure_caught = catch @signal_name do
      result = @procs.inject(value) do |res, p|
        p.call(res)
      end
      return result
    end
    @short_circuit_action.call(failure_caught)
  end
end
