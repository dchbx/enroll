require "benefit_markets/engine"
require 'benefit_markets/business_rules_engine'

require "virtus"
require "mongoid"
require "aasm"
require 'config'
require "slim"

module BenefitMarkets

    BENEFIT_MARKET_KINDS    = [:aca_shop, :aca_individual, :fehb, :medicaid, :medicare]
    PRODUCT_KINDS           = [:health, :dental, :term_life, :short_term_disability, :long_term_disability]
    PROBATION_PERIOD_KINDS  = [:first_of_month_before_15th, :date_of_hire, :first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days]

    # Time periods when sponsors may initially offer, and subsequently renew, benefits
    #   :monthly - may start first of any month of the year and renews each year in same month
    #   :annual  - may start only on benefit market's annual effective date month and renews each year in same month
    #   :annual_with_midyear_initial - may start mid-year and renew at subsequent annual effective date month
    APPLICATION_INTERVAL_KINDS  = [:monthly, :annual, :annual_with_midyear_initial]


    CONTACT_METHOD_KINDS        = [:paper_and_electronic, :paper_only, :electronic_only]

    CONTACT_METHODS_HASH = {
      :"Only Electronic communications" => :electronic_only,
      :"Only Paper communications" => :paper_only,
      :"Only Paper and Electronic communications" => :paper_and_electronic
    }


    class << self
      attr_writer :configuration
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


    # Constructs a symbol using an input string, stripping leading numbers and special characters, limiting
    # length, and leaving only lower case letters
    def self.string_to_symbol_key(string_value, max_length = 15)
      strip_leading_numbers(string_value.to_s).parameterize.gsub(/[-_]/,'').slice(0, max_length).to_sym
    end

    # Using an input string, return version of string with only non-numbers as first character
    def self.strip_leading_numbers(string_value)
      while string_value.chr.numeric? do
        string_value = string_value.slice!(1, string_value.length - 1)
      end
      string_value
    end


    # Ensure class type and integrity of date period ranges
    def self.tidy_date_range(range_period, attribute = nil)

      return range_period if (range_period.begin.class == Date) && (range_period.end.class == Date) && (range_is_increasing? range_period)

      case range_period.begin.class
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

    # Error classes
    class UndefinedProductKindError                 < StandardError; end
    class UndefinedContributionModelError           < StandardError; end
    class UndefinedBenefitOptionError               < StandardError; end
    class UndefinedPriceModelError                  < StandardError; end
    class CompositeRatePriceModelIncompatibleError  < StandardError; end

    class BenefitMarketCatalogError                 < StandardError; end

    class DuplicatePremiumTableError                < StandardError; end
    class InvalidEffectivePeriodError               < StandardError; end
    class InvalidEffectiveDateError                 < StandardError; end

end
