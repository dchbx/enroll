# frozen_string_literal: true

ActionMailer::Base.add_delivery_method :soa_mailer, MailDelivery::SoaMailer
