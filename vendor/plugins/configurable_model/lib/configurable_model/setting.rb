module ConfigurableModel
  module Setting
    extend ActiveSupport::Concern

    included do

      include Mongoid::Document
      include Mongoid::Timestamps

      field :label,       type: String  # fill using key like i18n in the form if not provided
      field :description, type: String

      field :key,         type: String  # benefit_markets.shop_market.initial_application
      field :value,       type: String
      field :default,     type: String, default: ''

      field :type,        type: String # list, date, number, boolean, string, range, datetime, day of month, days, year, months
      field :is_required, type: Boolean, default: true

      # list/enumerated...capture if user can choose multiple
      scope :get_all,  -> (starting_with) {
        where(key: /^#{::Regexp.escape(starting_with)}/i)
      }

      scope :by_key, -> (key) { 
        where(key: key)
      }

      index({ key: 1 }, { unique: true })

      validates_presence_of   :default, :is_required
      validates_uniqueness_of :key

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
    end
  end
end