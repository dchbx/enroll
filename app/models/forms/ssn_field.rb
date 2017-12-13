module Forms
  module SsnField
    def self.included(base)
      base.class_eval do
        attr_reader :ssn, :no_ssn

        def ssn=(new_ssn)
          if !new_ssn.blank?
            @ssn = new_ssn.to_s.gsub(/\D/, '')
          end
        end

        def no_ssn=(no_ssn)
          @no_ssn = no_ssn
        end

        def invalid_ssn_formats
          object = Person.new(ssn: ssn)
          ssn_errors = object.send(:is_ssn_composition_correct?)
          errors.add(:base, ssn_errors.join(',')) if ssn_errors.present?
        end
      end
    end
  end
end
