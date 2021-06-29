# frozen_string_literal: true

class DeviseCustomMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'

  self.delivery_method = :soa_mailer if Rails.env.production?
end
