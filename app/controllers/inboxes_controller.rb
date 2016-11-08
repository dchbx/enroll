class InboxesController < ApplicationController
  before_action :find_inbox_provider, except: [:msg_to_portal]
  before_action :find_hbx_profile, only: [:new, :create]
  before_action :find_message, only: [:show, :destroy]
  before_action :set_inbox_and_assign_message, only: [:create]

  def new
    @new_message = @inbox_provider.inbox.messages.build
  end

  def create
    @new_message.folder = Message::FOLDER_TYPES[:inbox]

    @inbox.post_message(@new_message)
    if @inbox.save
      create_sent_message
      flash[:notice] = "Successfully sent message."
      redirect_to successful_save_path
    else
      render "new"
    end
  end

  def show
    @message.update_attributes(message_read: true) unless current_user.has_hbx_staff_role?
    respond_to do |format|
      format.html
      format.js
    end
  end


  def destroy
    #@message.destroy
    @message.update_attributes(folder: Message::FOLDER_TYPES[:deleted])
    flash[:notice] = "Successfully deleted inbox message."
    if params[:url].present?
      @inbox_url = params[:url]
    end
  end

  private

  def create_sent_message
    sent_message = @new_message.dup
    sent_message.folder = Message::FOLDER_TYPES[:sent]
    sent_message.parent_message_id = @new_message._id
    inbox = @profile.inbox
    inbox.post_message(sent_message)
    inbox.save!
  end

  def find_hbx_profile
    @profile = HbxProfile.find(params["profile_id"])
  end

  def find_message
    @message = @inbox_provider.inbox.messages.by_message_id(params["message_id"]).to_a.first
  end

  def set_inbox_and_assign_message
    @inbox = @inbox_provider.inbox
    @new_message = Message.new(params.require(:message).permit!)
  end
end
