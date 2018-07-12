module BenefitSponsors
  module Organizations
    class OrganizationForms::PhoneForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :kind, String
      attribute :area_code, String
      attribute :number, String
      attribute :extension, String
      attribute :office_kind_options, Array
      
      validates_presence_of :kind, :area_code, :number

      validates :area_code,
                numericality: true,
                length: { minimum: 3, maximum: 3, message: "%{value} is not a valid area code" },
                allow_blank: false

      validates :number,
                numericality: true,
                length: { minimum: 7, maximum: 7, message: "%{value} is not a valid phone number" },
                allow_blank: false


      def persisted?
        false
      end

      def number=(val)
        number = val.gsub("-", "")
        super number
      end

    end
  end
end
