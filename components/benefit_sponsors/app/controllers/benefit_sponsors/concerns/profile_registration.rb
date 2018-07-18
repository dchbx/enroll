module BenefitSponsors
  module Concerns
    module ProfileRegistration

      private

      def broker_new_registration_url
        new_profiles_registration_path(profile_type: "broker_agency")
      end

      def sponsor_new_registration_url
        new_profiles_registration_path(profile_type: "benefit_sponsor")
      end

      def sponsor_show_pending_registration_url
        show_pending_profiles_employers_employer_profiles_path
      end

      def sponsor_home_registration_url(profile_id)
        profiles_employers_employer_profile_path(profile_id, tab: 'home')
      end

      def agency_edit_registration_url
        edit_profiles_registration_path(@agency.organization.profile.id)
      end

      def broker_show_registration_url(profile_id=nil)
        profiles_broker_agencies_broker_agency_profile_path(profile_id || @agency.organization.profile.id)
      end

      def agency_home_url(profile_id)
        if is_employer_profile?
          sponsor_home_registration_url(profile_id)
        elsif is_broker_profile?
          broker_show_registration_url(profile_id)
        end
      end

      def sign_up_url
        main_app.new_user_registration_path
      end

      def method_missing(name, *args, &block)
        if name.to_s.match(/@/)
          method_name, attribute = name.to_s.split("@")
          return self.send(method_name, attribute)
        end
        super
      end
    end
  end
end
