module MailDelivery
  class SoaMailer
    include Acapi::Notifiers

    def initialize(*vals)
      # A slug because mail insists on invoking it
    end

    def deliver!(mail)
      subject = mail.subject
      body = mail.body.raw_source
      mail.to.each do |recipient|
        send_email_html(recipient, subject, body)
      end
    end
  end
end
