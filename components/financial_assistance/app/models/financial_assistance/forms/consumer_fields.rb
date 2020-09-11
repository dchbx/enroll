# frozen_string_literal: true

module FinancialAssistance
  module Forms
    module ConsumerFields
      def self.included(base) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        base.class_eval do
          attr_accessor :race, :ethnicity, :language_code, :citizen_status, :tribal_id
          attr_accessor :is_incarcerated, :is_disabled, :citizen_status
          attr_accessor :vlp_subject, :alien_number, :i94_number, :visa_number, :passport_number, :sevis_id, :naturalization_number, :receipt_number, :citizenship_number, :card_number, :country_of_citizenship, :issuing_country, :status

          def us_citizen=(val)
            @us_citizen = (val.to_s == "true")
            @naturalized_citizen = false if val.to_s == "false"
          end

          def naturalized_citizen=(val)
            @naturalized_citizen = (val.to_s == "true")
          end

          def indian_tribe_member=(val)
            @indian_tribe_member = (val.to_s == "true") if val.to_s.present?
          end

          def eligible_immigration_status=(val)
            @eligible_immigration_status = (val.to_s == "true")
          end

          def expiration_date
            @expiration_date
          end

          def expiration_date=(val)
            @expiration_date = Date.strptime(val, '%m/%d/%Y') if val.to_s.present?
          end

          def us_citizen
            return @us_citizen unless @us_citizen.nil?
            return nil if @citizen_status.blank?
            @us_citizen ||= ::ConsumerRole::US_CITIZEN_STATUS_KINDS.include?(@citizen_status)
          end

          def naturalized_citizen
            return @naturalized_citizen unless @naturalized_citizen.nil?
            return nil if @us_citizen.nil? || @us_citizen
            @naturalized_citizen ||= (::ConsumerRole::NATURALIZED_CITIZEN_STATUS == @citizen_status)
          end

          def indian_tribe_member
            return @indian_tribe_member unless @indian_tribe_member.nil?
            return nil if @indian_tribe_member.nil?
            @indian_tribe_member ||= (@indian_tribe_member == true)
          end

          def eligible_immigration_status
            return @eligible_immigration_status unless @eligible_immigration_status.nil?
            return nil if @us_citizen.nil? || !@us_citizen
            @eligible_immigration_status ||= (::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS == @citizen_status)
          end

          def assign_citizen_status
            @citizen_status = if naturalized_citizen
                                ::ConsumerRole::NATURALIZED_CITIZEN_STATUS
                              elsif us_citizen
                                ::ConsumerRole::US_CITIZEN_STATUS
                              elsif eligible_immigration_status
                                ::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS
                              elsif !eligible_immigration_status.nil?
                                ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
                              end
          end

          def consumer_role=(_val)
            true
          end
        end
      end
    end
  end
end
