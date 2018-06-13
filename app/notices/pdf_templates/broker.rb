module PdfTemplates
  class Broker
    include Virtus.model

    attribute :primary_fullname, String
    attribute :organization, String
    attribute :address, PdfTemplates::NoticeAddress
    attribute :phone, String
    attribute :email, String
    attribute :web_address, String
    attribute :mpi_indicator, String
    attribute :hbe, PdfTemplates::Hbe
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer_name
    attribute :full_name, String
    attribute :hbx_id, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :assignment_date, Date
    attribute :full_name, String
    attribute :terminated_on, Date
    attribute :agency, String
  end

  def shop?
    false
  end

end
