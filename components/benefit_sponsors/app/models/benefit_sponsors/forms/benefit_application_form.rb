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
      attribute :sponsor_profile_id, String
      attribute :start_on_options, Hash
      attribute :admin_datatable_action, Boolean, default: false
      attribute :has_active_ba, Boolean, default: false

      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      validates_presence_of :fte_count, :pte_count, :msp_count, :benefit_sponsorship_id

      validate :validate_oe_dates
      # validates :validate_application_dates
      attr_reader :service, :show_page_model

      def service
        return @service if defined? @service
        @service = BenefitSponsors::Services::BenefitApplicationService.new
      end

      def self.for_new(params)
        form = self.new(params)
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

      def self.for_update(args)
        # for update why are we creating new
        form = self.new(id: args[:id], benefit_sponsorship_id: args[:benefit_sponsorship_id])
        form.service.load_form_params_from_resource(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.fetch(args)
        #why are we creating new insted of fetching
        form = self.new(id: args[:benefit_application_id], benefit_sponsorship_id: args[:benefit_sponsorship_id])
        form.service.find_benefit_sponsorship(form)
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

      def force_submit_application_with_eligibility_errors
        save_result, persisted_object = service.force_submit_application_with_eligibility_errors(self)
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

      def is_ineligible_to_submit?
        errors.messages.keys.include?(:attestation_ineligible) || errors.messages.keys.include?(:employer_primary_office_location) || errors.messages.keys.include?(:benefit_application_fte_count)
      end

      def save
        persist
      end

      def update_attributes(params)
        self.attributes = params
        persist(update: true)
      end

      def validate_oe_dates
        return false unless open_enrollment_start_on.present? && open_enrollment_end_on.present?
        oe_start = parse_date_from_string(open_enrollment_start_on)
        oe_end = parse_date_from_string(open_enrollment_end_on)
        if admin_datatable_action && oe_end <= oe_start
          errors.add(:base, "Open Enrollment Start Date can't be later than the Open Enrollment End Date")
        elsif id.nil? && oe_start >= oe_end
          errors.add(:base, "Open Enrollment Dates are not valid")
        end
      end

      def parse_date_from_string(string)
        Date.strptime(string, '%m/%d/%Y')
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
