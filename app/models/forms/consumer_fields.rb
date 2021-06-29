# frozen_string_literal: true

module Forms
  module ConsumerFields
    def self.included(base)
      base.class_eval do
        attr_accessor :race, :ethnicity, :language_code, :citizen_status, :tribal_id
        attr_accessor :is_incarcerated, :is_disabled, :citizen_status

        def us_citizen=(val)
          return  if val.to_s.blank?

          @us_citizen = (val.to_s == "true")
          @naturalized_citizen = false if val.to_s == "false"
        end

        def naturalized_citizen=(val)
          return  if val.to_s.blank?

          @naturalized_citizen = (val.to_s == "true")
        end

        def indian_tribe_member=(val)
          @indian_tribe_member = if val.to_s.present?
                                   (val.to_s == "true")
                                 end
        end

        def eligible_immigration_status=(val)
          return if val.to_s.blank?

          @eligible_immigration_status = (val.to_s == "true")
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
      end
    end
  end
end
