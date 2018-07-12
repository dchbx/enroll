module BenefitSponsors
  module Inboxes
    class MessagesController < ApplicationController
      before_action :set_current_user
      before_action :find_inbox_provider, except: [:msg_to_portal]
      before_action :find_message
      before_action :set_sent_box, only: [:show, :destroy], if: :is_broker?
      before_action :find_profile, only: [:msg_to_portal]

      def new
      end

      def create
      end

      def show
        BenefitSponsors::Services::MessageService.for_show(@message, @current_user)
        respond_to do |format|
          format.html
          format.js
        end
      end

      def destroy
        BenefitSponsors::Services::MessageService.for_destroy(@message)
        flash[:notice] = "Successfully deleted inbox message."
        if params[:url].present?
          @inbox_url = params[:url]
        end
      end

      def msg_to_portal
        @inbox_provider = @profile
        @inbox_provider_name = @inbox_provider.try(:legal_name)
        @inbox_to_name = "HBX Admin"
        log("#3969 and #3985 params: #{params.to_s}, request: #{request.env.inspect}", {:severity => "error"}) if @inbox_provider.blank?
        @new_message = @inbox_provider.inbox.messages.build
      end

      private

      def set_current_user
        @current_user = current_user
      end

      def set_sent_box
        @sent_box = true
      end

      def is_broker?
        return (@inbox_provider.class.to_s == "Person") && (/.*BrokerAgencyProfile$/.match(@inbox_provider.broker_role.broker_agency_profile._type))
      end

      def find_inbox_provider
        person = Person.where(id: params["id"])

        if person.present? && person.first.broker_role.present?
          @inbox_provider = person.first
        elsif find_profile.present?
          @inbox_provider = find_profile
          @inbox_provider_name = @inbox_provider.legal_name if /.*EmployerProfile$/.match(@inbox_provider._type)
        end
      end

      def find_profile
        @profile = BenefitSponsors::Organizations::Profile.find(params["id"])
      end

      def find_message
        @message = @inbox_provider.inbox.messages.by_message_id(params["message_id"]).to_a.first
      end

      def set_inbox_and_assign_message
      end

      def successful_save_path
      end
    end
  end
end