module ModelEvents
  class ModelEvent
    
    attr_accessor :event_key, :klass_instance, :options

    def initialize(event_key, klass_instance, options ={})
      @event_key = event_key
      @klass_instance = klass_instance
      @options = options
    end
  end
end