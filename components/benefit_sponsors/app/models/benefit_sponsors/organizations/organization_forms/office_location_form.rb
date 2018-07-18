module BenefitSponsors
  module Organizations
    class OrganizationForms::OfficeLocationForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :id, String
      attribute :is_primary, Boolean
      attribute :_destroy, Boolean
      attribute :address, ::BenefitSponsors::Organizations::OrganizationForms::AddressForm
      attribute :phone, ::BenefitSponsors::Organizations::OrganizationForms::PhoneForm

      alias_method :is_primary?, :is_primary

      validate :office_location_form

      def persisted?
        false
      end

      def phone_attributes=(phone)
        self.phone = ::BenefitSponsors::Organizations::OrganizationForms::PhoneForm.new(phone)
      end

      def address_attributes=(address)
        self.address = ::BenefitSponsors::Organizations::OrganizationForms::AddressForm.new(address)
        set_is_primary_field(self.address) if self.address
      end

      def set_is_primary_field(address_form)
        self.is_primary = address_form.kind == "primary" ? true : false
      end

      def office_location_form
        validate_form(self.address)
        validate_form(self.phone)
      end

      def validate_form(form)
        unless form.valid?
          self.errors.add(:base, form.errors.full_messages)
        end if form.present?
      end
    end
  end
end
