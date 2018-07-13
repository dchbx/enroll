module BenefitSponsors
  module Forms
    class Site
      extend  ActiveModel::Naming

      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations

      include Virtus.model

      attribute :id, String
      attribute :site_key, String
      attribute :long_name, String
      attribute :short_name, String
      attribute :domain_name, String
      attribute :byline, String
      attribute :copyright_period_start, String
      attribute :site_organizations_count, String
      attribute :owner_organization, BenefitSponsors::Forms::ExemptOrganization

      # Create a form for the 'new' action.
      # Note that usually this method may have few parameters
      #   other than current user.
      # @return [SiteForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_new
        service.attributes_to_form_params(service.build, new)
      end

      # Create a form for the 'create' action, populated with the provided
      #   parameters from the controller.
      # @param params [Hash] the params for :site from the controller
      # @return [SiteForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_create(params)
        new params
      end

      # Find the existing form corresponding to the given ID.
      # @param id [Object] an opaque ID from the controller parameters
      # @return [SiteForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_edit(id)
        new find_for(id)
      end

      # Find the 'update' form corresponding to the given ID.
      # @param id [Object] an opaque ID from the controller parameters
      # @return [SiteForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_update(id)
        new find_for(id)
      end

      def self.find_for(id)
        params_form = new(id: id)
        form = service.load_form_params_from_resource(params_form)
        service.load_form_params_from_resource(params_form)
      end

      def self.service
        @service ||= BenefitSponsors::Services::SiteService.new
      end

      def service
        @service ||= BenefitSponsors::Services::SiteService.new
      end

      def save
        persist
      end

      def update_attributes(params)
        self.attributes = params
        service.update(self)
      end

      def persist
        return false unless valid?
        service.save(self)
      end

      # Forms cannot be persisted
      def persisted?
        self.id.present?
      end

      def owner_organization_attributes=(owner_organization)
        self.owner_organization = BenefitSponsors::Forms::ExemptOrganization.new(owner_organization)
      end
    end
  end
end
