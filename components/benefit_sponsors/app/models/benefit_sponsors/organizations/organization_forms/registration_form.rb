module BenefitSponsors
  module Organizations
    class OrganizationForms::RegistrationForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :current_user_id, String
      attribute :profile_type, String
      attribute :portal, Boolean
      attribute :profile_id, String
      attribute :staff_roles, Array[OrganizationForms::StaffRoleForm]
      attribute :organization, OrganizationForms::OrganizationForm

      validate :registration_form

      def staff_roles_attributes=(attrs)
        self.staff_roles = attrs.values.inject([]) do |result, role|
          result << OrganizationForms::StaffRoleForm.new(role)
          result
        end
      end

      def organization=(val)
        result = super val
        profile = result.profile
        profile.profile_type = profile_type
        result
      end

      def persisted?
        if profile_id.present?
          return true
        end
        false
      end

      def self.for_new(attrs)
        service = resolve_service(profile_type: attrs[:profile_type])
        form_params = service.build(profile_type: attrs[:profile_type])
        new(form_params.merge!({
          portal: attrs[:portal]
        }))
      end

      def self.for_create(attrs)
        service = resolve_service(profile_type: attrs[:profile_type])
        form_params = service.load_form_metadata(new(attrs))
        new(form_params)
      end

      def self.for_edit(profile_id)
        service = resolve_service(profile_id)
        form_params = service.find
        new(form_params)
      end

      def self.for_update(attrs)
        service = resolve_service(profile_id: attrs[:profile_id])
        attrs.merge!({
          profile_type: service.profile_type
        })
        form = new(attrs)
      end

      def save
        persist!
      end

      def update
        update!
      end

      def persist!
        return false unless valid?
        service({profile_type: profile_type}).store!(self)
      end

      def update!
        return false, :agency_edit_registration_url unless valid?
        service({profile_id: profile_id}).store!(self)
      end

      def registration_form
        validate_staff_role
        validate_form(self.organization)
        validate_form(self.organization.profile)
        validate_office_locations(self.organization.profile)
      end

      def validate_staff_role
        self.staff_roles.each do |staff_role|
          validate_form(staff_role)
        end
      end

      def validate_office_locations(profile_form)
        profile_form.office_locations.each do |location_form|
          validate_form(location_form)
        end
      end

      def validate_form(form)
        unless form.valid?
          self.errors.add(:base, form.errors.full_messages)
        end
      end

      protected

      def self.resolve_service(attrs ={})
        BenefitSponsors::Services::NewProfileRegistrationService.new(attrs)
      end

      def service(attrs={})
        return @service if defined?(@service)
        @service = self.class.resolve_service(attrs)
      end

      private

      def build(profile_type)
        service.build({profile_type: profile_type})
      end
    end
  end
end
