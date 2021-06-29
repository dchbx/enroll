# frozen_string_literal: true

module GeneralAgencies
  class InboxesController < InboxesController
    include Acapi::Notifiers

    def new
      @inbox_provider_name = 'HBX Admin.'
      @inbox_to_name = @general_agency_provider.try(:legal_name)
      @inbox_provider = @general_agency_provider
      super
    end

    def msg_to_portal
      @general_agency_provider = GeneralAgencyProfile.find(params["inbox_id"])
      @inbox_provider = @general_agency_provider
      @inbox_provider_name = @inbox_provider.try(:legal_name)
      @inbox_to_name = "HBX Admin"
      @new_message = @inbox_provider.inbox.messages.build
    end

    def create
      if params['message']['to'] == 'HBX Admin'
        @new_message.folder = Message::FOLDER_TYPES[:sent]
        inbox_message = @new_message.dup
        inbox_message.folder = Message::FOLDER_TYPES[:inbox]
        to_inbox = @profile.inbox
        to_inbox.post_message(inbox_message)
        @inbox.post_message(@new_message)
        if @inbox.save && to_inbox.save
          flash[:notice] = "Successfully sent message."
          redirect_to general_agencies_profile_path(id: params['id'])
        else
          render "new"
        end
      else
        super
      end
    end

    def destroy
      @sent_box = true
      super
    end

    def show
      @sent_box = true
      super
    end

    def find_inbox_provider
      id = params["id"] || params['profile_id']
      if current_user.person._id.to_s == id
        @inbox_provider = current_user.person
      else
        @general_agency_provider = GeneralAgencyProfile.find(params["id"] || params['profile_id'])
        @inbox_provider = @general_agency_provider
      end
    end

    def successful_save_path
      exchanges_hbx_profiles_root_path
    end
  end
end
