module BenefitMarkets
	module Configurations
	  class Configuration # change to setting
	    include Mongoid::Document
	    include Mongoid::Timestamps

	    embedded_in :benefit_market

      field :key,         type: String
      field :value,       type: String
      field :default,     type: String

      # field :site_key,    type: String ?? 
      # field :language,    type: Symbol  # :en

      field :is_required, type: Boolean, default: false
      field :description, type: String

      scope :get_all,  -> (starting_with) {
        where(key: /^#{::Regexp.escape(starting_with)}/i)
      }

      scope :by_key, -> (key) { 
        where(key: key)
      }

      index({ key: 1 }, { unique: true })

      validates_presence_of   :default, :is_required
      validates_uniqueness_of :key

      def write_cache
        Rails.cache.write(cache_key, (value || default))
      end

      def expire_cache
        Rails.cache.delete(cache_key)
      end

      def cache_key
        self.class.cache_key(key, benefit_market)
      end

      def value=(val)
        write_attribute(:value, serialize_value(val))
      end

      def default=(val)
        write_attribute(:default, serialize_value(val))
      end

      def serialize_value(val)
        return nil if val.blank?

        if val.to_s.scan(/<%/).present?
          ERB.new(val).src
        else
          val.inspect
        end
      end

      class << self

        def cache_key(key, scope_object)
          scope = ["configurations"]
          scope << "#{scope_object.class.name}-#{scope_object.id}" if scope_object
          scope << key.to_s
          scope.join("-")
        end

        def [](benefit_market, key)
          Rails.cache.fetch(cache_key(key, benefit_market)) do
            setting = find_setting(benefit_market, key)
            parse_value(setting)
          end
        end

        # set a setting value by [] notation
        def []=(benefit_market, key, attrs)
          find_or_initialize_setting(benefit_market, key).tap do |setting|
            setting.attributes = attrs
            setting.save!
            setting.write_cache
          end
        end

        def find_or_initialize_setting(benefit_market, key)
          find_setting(benefit_market, key) || benefit_market.configurations.new(key: key)
        end

        def find_setting(benefit_market, key)
          benefit_market.configurations.by_key(key).first
        end

        def parse_value(setting)
          value_parser = proc {|value|
            $SAFE = 2
            eval(value)
          }
 
          value_parser.call(setting.value || setting.default)
        end
      end
	  end
	end
end