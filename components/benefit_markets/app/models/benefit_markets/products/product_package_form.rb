module BenefitMarkets
  module Products
    class ProductPackageForm
      include Virtus.model
      include ActiveModel::Model
      include ActiveModel::Validations

      attribute :id, String

      attribute :benefit_catalog_id, String
      attribute :benefit_kind, String
      attribute :contribution_model_id, String
      attribute :pricing_model_id, String
      attribute :product_kind, String
      attribute :package_kind, String
      attribute :health_package_kind, String
      attribute :dental_package_kind, String
      attribute :title, String

      attribute :allowed_benefit_kinds, Array
      attribute :available_benefit_catalogs, Array
      attribute :available_benefit_kinds, Array
      attribute :available_contribution_models, Array
      attribute :available_pricing_models, Array
      attribute :available_product_kinds, Array
      attribute :available_health_package_kinds, Array
      attribute :available_dental_package_kinds, Array
      attribute :available_default_package_kinds, Array

      attr_reader :show_page_model

      validates_presence_of :title, :allow_blank => false
      validates_presence_of :pricing_model_id, :allow_blank => false
      validates_presence_of :contribution_model_id, :allow_blank => false
      validates_presence_of :benefit_catalog_id, :allow_blank => false
      validates_inclusion_of :benefit_kind, :in => :allowed_benefit_kinds, :allow_blank => false

      # Create a form for the 'new' action.
      # Note that usually this method may have few parameters
      #   other than current user.
      # @param benefit_kind [String] the benefit option kind
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_new
        form = service.attributes_to_form_params(service.build, new)
        service.load_default_form_params(form)
        service.load_form_metadata(form)
        form
      end

      # Create a form for the 'create' action, populated with the provided
      #   parameters from the controller.
      # @param params [Hash] the params for :product_package from the controller
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_create(params)
        form = new params
        service.load_form_metadata(form)
        form
      end

      # Find the existing form corresponding to the given ID.
      # @param id [Object] an opaque ID from the controller parameters
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_edit(params)
        find_for(params)
      end

      # Find the 'update' form corresponding to the given ID.
      # @param id [Object] an opaque ID from the controller parameters
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_update(id)
        find_for(id)
      end

      # Validate and attempt to save the form.
      # This method will populate the errors.
      # @return [Boolean] the result of the attempted save
      def save
        persist
      end

      # Validate and attempt to persist updates.
      # This method will populate the errors.
      # @return [Boolean] the result of the attempted update
      def update_attributes(params)
        self.attributes = params
        persist(update: true)
      end

      # Has this form been successfully saved before?  Used mainly by form_for.
      # @return [Boolean] true if previously saved, otherwise false
      def persisted?
        id.present?
      end

      # Return the class of the policy which should be used by pundit.
      # @return [Class] the class of the policy to be used
      def policy_class
        BenefitMarkets::Products::ProductPackageFormPolicy
      end

      # @!visibility private
      def has_additional_attributes?
        false
      end

      protected

      def self.service
        @service ||= ProductPackageService.new
      end

      def service
        @service ||= ProductPackageService.new
      end

      def self.find_for(params)
        form = service.load_form_params_from_resource(new(params))
        service.load_form_metadata(form)
        form
      end

      def persist(update: false)
        return false unless self.valid?
        persist_result, persisted_object = update ? service.update(self) : service.save(self)
        return false unless persist_result
        @show_page_model = [service.benefit_catalog_for(self), persisted_object]
        true
      end
    end
  end
end
