# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base

  default from: Settings.site.mail_address

  self.delivery_method = :soa_mailer if Rails.env.production?

  def notice_email(notice)
    mail({ to: notice.to, subject: notice.subject}) do |format|
      format.html { notice.html }
    end
  end
end
