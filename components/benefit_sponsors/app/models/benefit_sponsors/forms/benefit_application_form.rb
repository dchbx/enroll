module BenefitSponsors
  module Forms
    class BenefitApplicationForm

      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :start_on, String
      attribute :end_on, String
      attribute :open_enrollment_start_on, String
      attribute :open_enrollment_end_on, String
      attribute :fte_count, Integer, default: 0
      attribute :pte_count, Integer, default: 0
      attribute :msp_count, Integer, default: 0
      attribute :benefit_packages, Array[BenefitSponsors::Forms::BenefitPackageForm]

      attribute :id, String
      attribute :benefit_sponsorship_id, String
      attribute :start_on_options, Hash

      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      validates_presence_of :fte_count, :pte_count, :msp_count, :benefit_sponsorship_id

      # validates :validate_application_dates
      attr_reader :service, :show_page_model

      def service
        return @service if defined? @service
        @service = BenefitSponsors::Services::BenefitApplicationService.new
      end

      def self.for_new(benefit_sponsorship_id)
        form = self.new(:benefit_sponsorship_id => benefit_sponsorship_id)
        form.service.load_default_form_params(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_create(params)
        form = self.new(params)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_edit(args)
        # for edit why are we creating new
        form = self.new(id: args[:id], benefit_sponsorship_id: args[:benefit_sponsorship_id])
        form.service.load_form_params_from_resource(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_update(id)
        # for update why are we creating new
        form = self.new(id: id)
        form.service.load_form_params_from_resource(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.fetch(id)
        #why are we creating new insted of fetching
        form = self.new(id: id)
        form
      end

      def persisted?
        id.present?
      end

      def submit_application
        save_result, persisted_object = service.submit_application(self)
        @show_page_model = persisted_object
        return false unless save_result
        true
      end

      def force_submit_application
        save_result, persisted_object = service.force_submit_application(self)
        @show_page_model = persisted_object
        true
      end

      def revert
        save_result, persisted_object = service.revert(self)
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

      def update_attributes(params)
        self.attributes = params
        persist(update: true)
      end

      def validate_application_dates
        if start_on <= end_on
          errors.add(:start_on, "can't be later than end on date")
        end
      end

      def is_renewing?
        benefit_packages.present? ? benefit_packages.first.service.benefit_application.is_renewing? : false
      end

    end
  end
end
