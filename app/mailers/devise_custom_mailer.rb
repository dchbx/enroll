class DeviseCustomMailer < Devise::Mailer   
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'

  if Rails.env.production?
    self.delivery_method = :soa_mailer
  end
end
