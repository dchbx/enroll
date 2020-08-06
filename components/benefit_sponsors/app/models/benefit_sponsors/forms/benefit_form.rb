# frozen_string_literal: true

module BenefitSponsors
  module Forms
    class BenefitForm

      include Virtus.model
      include ActiveModel::Model

      attribute :benefit_package_id, String
      attribute :benefit_application_id, String
      attribute :benefit_sponsorship_id, String
      attribute :sponsored_benefit_id, String # This will be the current SB which we're working on
      attribute :kind, String
      attribute :sponsored_benefit, BenefitSponsors::Forms::SponsoredBenefitForm

      attr_accessor :service, :catalog


      def self.for_new(params)
        form = self.new(params)
        form.sponsored_benefit = BenefitSponsors::Forms::SponsoredBenefitForm.new(kind: params[:kind])
        form.service = resolve_service(params)
        form.service.load_form_meta_data(form)
      end

      def self.for_create(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form
      end

      def self.for_edit(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form_attributes = form.service.find(form.sponsored_benefit_id)
        form.sponsored_benefit = BenefitSponsors::Forms::SponsoredBenefitForm.new(form_attributes)
        form.service.load_form_meta_data(form)
      end

      def self.for_update(params)
        form = self.new(params)
        form.service = resolve_service(params)
        form
      end

      def self.fetch(params)
        form = self.new(params)
        form.sponsored_benefit = BenefitSponsors::Forms::SponsoredBenefitForm.new(kind: params[:kind], id: form.sponsored_benefit_id)
        form.service = resolve_service(params)
        form.service.load_form_meta_data(form)
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

      def self.resolve_service(attrs = {})
        @service = BenefitSponsors::Services::SponsoredBenefitService.new(attrs)
      end

      def sponsored_benefit_attributes=(attributes)
        self.sponsored_benefit = BenefitSponsors::Forms::SponsoredBenefitForm.new(attributes)
      end

      def id=(val)
        self.sponsored_benefit_id = val
      end
    end
  end
end
