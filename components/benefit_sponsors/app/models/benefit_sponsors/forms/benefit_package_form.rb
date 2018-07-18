module BenefitSponsors
  module Forms
    class BenefitPackageForm

      include Virtus.model
      include ActiveModel::Model

      attribute :id, String
      attribute :title, String
      attribute :description, String
      attribute :probation_period_kind, Symbol
      attribute :benefit_application_id, String
      attribute :sponsored_benefits, Array[BenefitSponsors::Forms::SponsoredBenefitForm]
      attribute :parent, BenefitSponsors::Forms::BenefitApplicationForm
      attribute :probation_period_display_name, String

      attribute :is_new_package, Boolean

      attr_accessor :catalog, :sponsored_benefits

      # attr_accessor :benefit_application, :product_packages
      # validates :title, presence: true

      validates_presence_of :title, :probation_period_kind
      validate :benefit_package_info

      attr_reader :service, :show_page_model

      def sponsored_benefits_attributes=(attributes)
        @sponsored_benefits ||= []
        attributes.each do |i, sponsored_benefit_attributes|
          @sponsored_benefits.push(SponsoredBenefitForm.new(sponsored_benefit_attributes))
        end
      end

      def service
        return @service if defined? @service
        @service = BenefitSponsors::Services::BenefitPackageService.new
      end

      def self.for_new(benefit_application_id)
        form = self.new(:benefit_application_id => benefit_application_id)
        form.sponsored_benefits = SponsoredBenefitForm.for_new
        form.service.load_default_form_params(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_create(params)
        form = self.new(params)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_edit(params, load_benefit_application_form)
        form = self.new(params)
        form.service.load_form_params_from_resource(form, load_benefit_application_form)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_update(params)
        form = self.new(params)
        form.service.load_form_metadata(form)
        form.service.load_form_params_from_previous_selection(form)
        form
      end

      def self.for_calculating_employer_contributions(params)
        form = self.new(params)
        form.service.load_form_metadata(form)
        form.service.calculate_premiums(form)
      end

      def self.for_calculating_employee_cost_details(params)
        form = self.new(params)
        form.service.load_form_metadata(form)
        form.service.calculate_employee_cost_details(form)
      end

      def self.for_reference_product_summary(params, details)
        form = self.new(params)
        form.service.reference_product_details(form, details)
      end

      def self.fetch(params)
        form = self.new(params)
        form.service.load_form_metadata(form)
        form
      end

      def destroy
        save_result, persisted_object = service.disable_benefit_package(self)
        @show_page_model = persisted_object
        return false unless save_result
        true
      end

      def persist(update: false)
        return false unless self.valid?
        save_result, persisted_object = (update ? service.update(self) : service.save(self))
        return false unless save_result
        @show_page_model = persisted_object
        true
      end

      def save
        persist
      end

      def update
        persist(update: true)
      end

      def new_record?
        is_new_package
      end

      def benefit_package_info
        sponsored_benefits.each do |sponsored_benefit|
          validate_sponsored_benefit(sponsored_benefit)
          validate_sponsored_contribution(sponsored_benefit)
          validate_contribution_levels(sponsored_benefit)
        end
      end

      def validate_sponsored_benefit(sponsored_benefit)
        validate_form(sponsored_benefit)
      end

      def validate_sponsored_contribution(sponsored_benefit)
        sponsor_contribution = sponsored_benefit.sponsor_contribution
        return if sponsor_contribution.blank?
        validate_form(sponsor_contribution)
      end

      def validate_contribution_levels(sponsored_benefit)
        sponsor_contribution = sponsored_benefit.sponsor_contribution
        return if sponsor_contribution.blank?
        contribution_levels = sponsor_contribution.contribution_levels
        contribution_levels.each do |contribution_level|
          validate_form(contribution_level)
        end
      end

      def validate_form(form)
        unless form.valid?
          self.errors.add(:base, form.errors.full_messages)
        end
      end

      def products_total
        case sponsored_benefits.first.product_package_kind
        when "single_issuer"
          catalog.plan_options[:single_issuer][sponsored_benefits.first.reference_product.issuer_name].count
        when "single_product"
          catalog.plan_options[:single_product][sponsored_benefits.first.reference_product.issuer_name].count
        when "metal_level"
          catalog.plan_options[:metal_level][sponsored_benefits.first.reference_product.metal_level_kind.to_sym].count
        end
      end
    end
  end
end
