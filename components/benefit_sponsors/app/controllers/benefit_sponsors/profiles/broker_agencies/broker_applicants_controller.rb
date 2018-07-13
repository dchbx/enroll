module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerApplicantsController < ::BenefitSponsors::ApplicationController
        include Exchanges::BrokerApplicantsHelper

        before_action :check_hbx_staff_role
        before_action :find_broker_applicant, only: [:edit, :update]

        def index
          @datatable = Effective::Datatables::BrokerApplicantsDataTable.new()
        end

        def edit
          respond_to do |format|
            format.js
          end
        end

        def update
        end

        private

        def send_secure_message_to_broker_agency(broker_role)
          hbx_admin = HbxProfile.all.first
          broker_agency = broker_role.broker_agency_profile

          subject = "Received new broker application - #{broker_role.person.full_name}"
          body = "<br><p>Following are broker details<br>Broker Name : #{broker_role.person.full_name}<br>Broker NPN  : #{broker_role.npn}</p>"
          secure_message(hbx_admin, broker_agency, subject, body)
        end

        def find_broker_applicant
          @broker_applicant = Person.find(BSON::ObjectId.from_string(params[:id]))
        end

        def check_hbx_staff_role
          unless current_user.has_hbx_staff_role?
            redirect_to exchanges_hbx_profiles_root_path, :flash => { :error => "You must be an HBX staff member" }
          end
        end
      end
    end
  end
end
