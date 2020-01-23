module BenefitSponsors
  module Forms
    class SponsoredBenefitForm

      include Virtus.model
      include ActiveModel::Model

      attribute :id, String
      attribute :kind, String
      attribute :product_option_choice, String
      attribute :product_package_kind, String, default: Settings.aca.default_dental_option_kind
      attribute :elected_product_choices, Array # used for dental choice model
      
      # for employee cost details
      attribute :employees_cost, Array[EmployeeCostForm]

      attribute :employer_estimated_monthly_cost, String
      attribute :employer_estimated_min_monthly_cost, String
      attribute :employer_estimated_max_monthly_cost, String

      attribute :products, Array[BenefitProductForm]
      attribute :reference_plan_id, String
      attribute :reference_product, Product

      attribute :sponsor_contribution, SponsorContributionForm
      attribute :pricing_determinations, Array[PricingDeterminationForm]

      attribute :benefit_package_id, String
      attribute :benefit_application_id, String
      attribute :benefit_sponsorship_id, String
      attribute :sponsored_benefit_id, String # This will be the current SB which we're working on

      attribute :is_new_benefit, Boolean, default: true

      attr_accessor :sponsor_contribution, :service, :catalog

      validates_presence_of :product_package_kind, :reference_plan_id, :sponsor_contribution

      validate :check_product_option_choice

      def sponsor_contribution_attributes=(attributes)
        attributes.permit! if attributes.is_a?(ActionController::Parameters)
        @sponsor_contribution = SponsorContributionForm.new(attributes)
      end

      def self.for_new(params)
        kinds.collect do |kind|
          form = self.new(kind: kind)
          form.sponsor_contribution = SponsorContributionForm.for_new({product_package: form.product_package_for(kind, params[:application])})
          form
        end
      end

      def self.for_new_benefit(params)
        form = self.new(params)
        #form.sponsored_benefit = BenefitSponsors::Forms::SponsoredBenefitForm.new(kind: params[:kind])
        form.service = resolve_service(params)
        form.service.load_form_meta_data(form)
      end

      def load_meta_data
        service.load_form_meta_data(self)
      end

      def self.resolve_service(attrs={})
        @service = BenefitSponsors::Services::SponsoredBenefitService.new(attrs)
      end

      def self.for_create(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form
      end

      def self.for_edit(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form.assign_attributes(form.service.find(form.id))
        form.is_new_benefit = false
        form.service.load_form_meta_data(form)
      end

      def self.for_update(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form.is_new_benefit = false
        form.service.load_benefit_catalog_to_form(form)
      end

      def self.fetch(params)
        form = self.new(params)
        # form.sponsored_benefit = BenefitSponsors::Forms::SponsoredBenefitForm.new(kind: params[:kind], id: form.sponsored_benefit_id)
        form.service = resolve_service(params)
        form.service.load_form_meta_data(form)
      end

      def self.for_destroy(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form
      end

      def destroy
        service.destroy(self)
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

      def self.for_calculating_employer_contributions(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form.service.load_form_meta_data(form)
        form.service.calculate_premiums(form)
      end

      def self.for_calculating_employee_cost_details(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form.service.load_form_meta_data(form)
        form.service.calculate_employee_cost_details(form)
      end

      def self.kinds
        %w(health)
        # get kinds from catalog based on products/product packages
      end

      def product_package_for(kind, application)
        catalog = application.benefit_sponsor_catalog
        catalog.product_packages.by_product_kind(kind.to_sym).first
      end

      def assign_attributes(atts)
        atts.each_pair do |k, v|
          self.send("#{k}=".to_sym, v)
        end
      end

      def check_product_option_choice
        return true if product_package_kind == 'multi_product'

        errors.add(:base, "product option choice can't be blank") if product_option_choice.blank?
      end
    end
  end
end
