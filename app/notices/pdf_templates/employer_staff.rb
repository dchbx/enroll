
module PdfTemplates
  class EmployerStaff
    include Virtus.model

    attribute :employer_first_name, String
    attribute :employer_phone, String
    attribute :employer_last_name, String
    attribute :employer_email, String
  end
end
