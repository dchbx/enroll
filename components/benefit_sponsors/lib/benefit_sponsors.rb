require "benefit_sponsors/engine"

require "mongoid"
require "aasm"
require 'config'
require 'dry-types'
require 'dry-validation'
require 'dry-struct'
require 'dry-monads'
require BenefitSponsors::Engine.root.join('app/domain/benefit_sponsors/types')


module BenefitSponsors

  # Isolate the namespace portion of the passed class
  def parent_namespace_for(klass)
    klass_name = klass.to_s.split("::")
    klass_name.slice!(-1) || []
    klass_name.join("::")
  end

  class << self
    attr_writer :configuration

    def event_listeners
      @event_listeners ||= Hash.new([])
    end

    # Add a new event listener for communicating between engines
    # Listener should be a constant or a string representing a constant,
    # and that class/module must respond to `.execute`.
    def add_event_listener(event, listener)
      event_listeners[event] = event_listeners[event] + [listener.to_s]
    end

    def publish_event(event, *args)
      event_listeners[event].map do |listener|
        Object.const_get(listener).execute(*args)
      end
    end

  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :settings
  end


  # Ensure class type and integrity of date period ranges
  def self.tidy_date_range(range_period, attribute = nil)
    if range_period.is_a?(Hash)
      period = range_period.deep_symbolize_keys
      range_period = period[:min]..period[:max] if period.key?(:min) && period.key?(:max)
    end

    return range_period if (range_period.begin.class == Date) && (range_period.end.class == Date) && (range_is_increasing? range_period)

    case range_period.begin
    when Date
      date_range  = range_period
    when String
      begin_on    = range_period.split("..")[0]
      end_on      = range_period.split("..")[1]
      date_range  = Date.strptime(beginning)..Date.strptime(ending)
    when Time, DateTime
      begin_on    = range_period.begin.to_date
      end_on      = range_period.end.to_date
      date_range  = begin_on..end_on
    else
      # @errors.add(attribute.to_sym, "values must be Date or Time") if attribute.present?
      return nil
    end

    if range_is_increasing?(date_range)
      return date_range
    else
      # @errors.add(attribute.to_sym, "end date may not preceed begin date") if attribute.present?
      return nil
    end
  end

  def self.range_is_increasing?(range)
    range.begin < range.end
  end

  class BenefitSponsorShipIneligibleError; end
end

