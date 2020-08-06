# frozen_string_literal: true

module BenefitSponsors
  module Services
    class BrokerManagementService

      def assign_agencies(form)
        assign_agencies_for_employer(form)
      end

      def terminate_agencies(form)
        terminate_agencies_for_employer(form)
      end

      private

      def terminate_agencies_for_employer(form)
        @employer_profile = BenefitSponsors::Organizations::Profile.find(form.employer_profile_id)
        if form.termination_date
          @employer_profile.fire_broker_agency(form.termination_date)
          @employer_profile.fire_general_agency!(form.termination_date)
          @employer_profile.save!
          true
        else
          false
        end
      end

      def assign_agencies_for_employer(form)
        @employer_profile = BenefitSponsors::Organizations::Profile.find(form.employer_profile_id)
        assign_broker_agency_for_emp(form.broker_agency_profile_id, form.broker_role_id)
        # # TODO fix this during notices implementation
        # send_notices_associated_to_employer_profile
      end

      def send_notification(broker_role_id)
        invitation = BenefitSponsors::Services::InvitationEmailService.new({broker_role_id: broker_role_id, employer_profile: @employer_profile})
        invitation.send_broker_successfully_associated_email
      rescue Exception => e
        puts e.inspect
        puts e.backtrace
      end

      def get_bson_id(id)
        BSON::ObjectId.from_string(id)
      end

      def assign_broker_agency_for_emp(broker_agency_profile_id, broker_role_id)
        broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(get_bson_id(broker_agency_profile_id))
        @employer_profile.broker_role_id = broker_role_id
        @employer_profile.hire_broker_agency(broker_agency_profile)
        @employer_profile.save!
        send_notification(broker_role_id)
      end

    end
  end
end
