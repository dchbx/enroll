module Forms
  module ConsumerFields
    def self.included(base)
      base.class_eval do
        attr_accessor :race, :ethnicity, :language_code
        attr_writer :us_citizen, :naturalized_citizen, :indian_tribe_member, :eligible_immigration_status
      end
    end
  end
end
