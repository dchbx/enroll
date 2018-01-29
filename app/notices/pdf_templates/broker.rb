module PdfTemplates
  class Broker
    include Virtus.model

    attribute :primary_fullname, String
    attribute :organization, String
    attribute :address, PdfTemplates::NoticeAddress
    attribute :phone, String
    attribute :email, String
    attribute :web_address, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :assignment_date, Date
    attribute :terminated_on, Date
  end
end
