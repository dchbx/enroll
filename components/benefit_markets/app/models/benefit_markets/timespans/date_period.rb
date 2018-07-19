module BenefitMarkets
  class Timespans::DatePeriod
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name,      type: String
    field :begin_on,  type: Date
    field :end_on,    type: Date

    validates_presence_of :begin_on, :end_on
    validate :ascending_dates

    # scope :find_on, ->(date){ where(:begin_on.lte => date, :end_on.gte => date).to_a unless date.blank?; binding.pry }
    scope :find_on,   ->(date){ where(:begin_on.lte => date, :end_on.gte => date) unless date.blank? }
    scope :find_name, ->(compare_name){ where(:name => compare_name) unless compare_name.blank? }

    def between?(compare_date)
      range_present? && (compare_date.between?(begin_on, end_on)) ? true : false
    end

    def to_range
      begin_on..end_on if range_present?
    end

    alias_method :min,        :begin_on
    alias_method :max,        :end_on
    alias_method :contains?,  :between?

    private

    def range_present?
      begin_on.present? && end_on.present?
    end

    def ascending_dates
      return unless range_present?
      errors.add(:begin_on, "must be earlier than End on #{end_on}") unless (begin_on <= end_on)
    end

  end
end
