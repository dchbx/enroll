module Forms
  module ConsumerFields
    def self.included(base)
      base.class_eval do
        attr_accessor :race, :ethnicity, :language_code, :citizen_status, :tribal_id
        attr_accessor :is_incarcerated, :is_disabled, :citizen_status , :has_primary_caregiver

        attr_writer :us_citizen, :naturalized_citizen, :indian_tribe_member, :eligible_immigration_status

        def us_citizen=(val)
          @us_citizen = (val.to_s == "true")
          @naturalized_citizen = false if val.to_s == "false"
        end

        def naturalized_citizen=(val)
          @naturalized_citizen = (val.to_s == "true")
        end

        def indian_tribe_member=(val)
          @indian_tribe_member = (val.to_s == "true")
        end

        def eligible_immigration_status=(val)
          @eligible_immigration_status = (val.to_s == "true")
        end

        def us_citizen
          return @us_citizen if !@us_citizen.nil?
          return nil if @citizen_status.blank?
          @us_citizen ||= ::ConsumerRole::US_CITIZEN_STATUS_KINDS.include?(@citizen_status)
        end

        def naturalized_citizen
          return @naturalized_citizen if !@naturalized_citizen.nil?
          return nil if @citizen_status.blank?
          @naturalized_citizen ||= (::ConsumerRole::NATURALIZED_CITIZEN_STATUS == @citizen_status)
        end

        def indian_tribe_member
          return @indian_tribe_member if !@indian_tribe_member.nil?
          return nil if @citizen_status.blank?
          @indian_tribe_member ||= (::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS == @citizen_status)
        end

        def eligible_immigration_status
          return @eligible_immigration_status if !@eligible_immigration_status.nil?
          return nil if @us_citizen.nil?
          return nil if @us_citizen
          return nil if @citizen_status.blank?
          @eligible_immigration_status ||= (::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS == @citizen_status)
        end

        def assign_citizen_status
          if indian_tribe_member
            @citizen_status = ::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS
          elsif naturalized_citizen
            @citizen_status = ::ConsumerRole::NATURALIZED_CITIZEN_STATUS
          elsif us_citizen
            @citizen_status = ::ConsumerRole::US_CITIZEN_STATUS
          elsif eligible_immigration_status
            @citizen_status = ::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS
          elsif (!eligible_immigration_status.nil?)
            @citizen_status = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
          else
            @citizen_status = nil
          end
        end
      end
    end
  end
end
