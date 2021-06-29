# frozen_string_literal: true

class IvlNotificationMailer < ApplicationMailer
  include ActionView::Helpers::UrlHelper
  after_action :send_inbox_notice

  def lawful_presence_verified(user)
    @user = user
    @view_type = "lawful_presence_verified"
    notice = IndividualNoticeBuilder.new(@user.parent, {template: "notices/9cindividual.html.erb"})
    attachments["notice.pdf"] = File.read(notice.send_pdf_notice)
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => @user.parent }}
    end
  end

  def lawful_presence_unverified(user)
    @user = user
    @view_type = "lawful_presence_unverified"
    notice = IndividualNoticeBuilder.new(@user.parent, {template: "notices/9findividual.html.erb"})
    attachments["notice.pdf"] = File.read(notice.send_pdf_notice)
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => @user.parent }}
    end
  end

  def lawfully_ineligible(user)
    @user = user
    @view_type = "lawfully_ineligible"
    notice = IndividualNoticeBuilder.new(@user.parent, {template: "notices/11individual.html.erb"})
    attachments["notice.pdf"] = File.read(notice.send_pdf_notice)
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => @user.parent }}
    end
  end

  private

  def send_inbox_notice
    if @user.parent && (to_inbox = @user.parent.inbox)
      @link = link_to('click here', Rails.application.routes.url_helpers.notification_consumer_profiles_path(view: @view_type)).html_safe
      new_message = to_inbox.messages.build(:subject => "DCHealthLink Notification", :body => "Please #{@link} to view the file")
      new_message.folder = Message::FOLDER_TYPES[:inbox]
      to_inbox.post_message(new_message)
      to_inbox.save!
    end
  end

end

