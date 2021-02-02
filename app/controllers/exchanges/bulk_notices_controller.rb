# frozen_string_literal: true

module Exchanges
  # Controller actions for bulk notices
  class BulkNoticesController < ApplicationController
    layout 'bootstrap_4'

    before_action :unread_messages
    before_action :set_current_user
    before_action :perform_authorization

    def index
      @bulk_notices = Admin::BulkNotice.all.order([:updated_at, :desc])
    end

    def show
      @bulk_notice = Admin::BulkNotice.find(params[:id])

      if @bulk_notice.aasm_state == 'draft'
        render 'preview'
      else
        render 'summary'
      end
    end

    def new
      #session[:bulk_notice] = { audience: {} }
      @entities = BenefitSponsors::Organizations::Organization.all_profiles.to_json
      @bulk_notice = Admin::BulkNotice.new
    end

    def create
      @bulk_notice = Admin::BulkNotice.new(user_id: current_user)

      if @bulk_notice.update_attributes(bulk_notice_params)
        @bulk_notice.upload_document(params, current_user) if params[:file]
        redirect_to exchanges_bulk_notice_path(@bulk_notice)
      else
        render 'new'
      end
    end

    def update
      @bulk_notice = Admin::BulkNotice.find(params[:id])

      if @bulk_notice.update_attributes(bulk_notice_params)
        @bulk_notice.upload_document(params, current_user) if params[:file].present?
        @bulk_notice.process! unless params[:commit] == "Preview"
        flash[:notice] = "Success, message sent!"
        redirect_to exchanges_bulk_notice_path(@bulk_notice)
      else
        render 'new'
      end
    end

    private

    def bulk_notice_params
<<<<<<< HEAD
      params.require(:admin_bulk_notice).permit(:audience_type, :subject, :body, audience_ids: [])
=======
      params.require(:admin_bulk_notice).except(:audience_identifiers, :user_id).permit(:audience_type, :subject, :body, audience_ids: [])
>>>>>>> 36180e398a... Bulk Upload Phase 2
    end

    def unread_messages
      profile = current_user.person.try(:hbx_staff_role).try(:hbx_profile)
      @unread_messages = profile.inbox.unread_messages.try(:count) || 0
    end

    def perform_authorization
      authorize HbxProfile, :can_send_secure_message?
    end
  end
end