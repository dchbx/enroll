# frozen_string_literal: true

class Maybe
  def initialize(obj)
    @value = obj
  end

  def fmap(&the_proc)
    @value.nil? ? Maybe.new(nil) : Maybe.new(the_proc.call(@value))
  end

  def method_missing(m, *args, &block)
    target = @value
    self.class.new(target.nil? ? nil : target.__send__(m, *args, &block))
  end

  def extract_value
    @value
  end
end
