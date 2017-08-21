module PdfTemplates
  class Hbe
    include Virtus.model

    attribute :url, String
    attribute :phone, String
    attribute :fax, String
    attribute :email, String
    attribute :address, PdfTemplates::NoticeAddress
    attribute :short_url, String

  end
end
