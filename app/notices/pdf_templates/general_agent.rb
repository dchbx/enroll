module PdfTemplates
  class GeneralAgent
    include Virtus.model

    attribute :phone, String
    attribute :email, String
    attribute :organization, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :full_name, String
    attribute :hbx_id, String

    def shop?
      true
    end
  end
end