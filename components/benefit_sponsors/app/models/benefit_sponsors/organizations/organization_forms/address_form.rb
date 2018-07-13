module BenefitSponsors
  module Organizations
    class OrganizationForms::AddressForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :address_1, String
      attribute :address_2, String
      attribute :city, String
      attribute :state, String
      attribute :zip, String
      attribute :kind, String
      attribute :county, String
      attribute :office_kind_options, Array
      attribute :state_options, Array

      validates_presence_of :address_1, :city, :state, :zip

      validates :zip,
                format: {
                    :with => /\A\d{5}(-\d{4})?\z/,
                    :message => "should be in the form: 12345 or 12345-1234"
                }


      def persisted?
        false
      end
    end
  end
end
