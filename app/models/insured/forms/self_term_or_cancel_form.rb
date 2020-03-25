# frozen_string_literal: true

module Insured
  module Forms
    class SelfTermOrCancelForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :carrier_logo,                      String
      attribute :enrollment,                        ::Insured::Forms::EnrollmentForm
      attribute :family,                            ::Insured::Forms::FamilyForm
      attribute :is_aptc_eligible,                  Boolean
      attribute :market_kind,                       String
      attribute :product,                           ::Insured::Forms::ProductForm
      attribute :term_date,                         Date
      attribute :elected_aptc_pct,                  String
      attribute :available_aptc,                    Float
      attribute :enable_tax_credit_btn,             Boolean
      attribute :new_effective_on,                  Date
      attribute :default_tax_credit_value,          Float
      attribute :new_enrollment_premium,            Float

      validates :market_kind,                       presence: true

      def self.for_view(attrs)
        service     = self_term_or_cancel_service(attrs)
        form_params = service.find
        form_params.merge!({enable_tax_credit_btn: check_to_enable_tax_credit_btn(attrs)})
        new(form_params)
      end

      def self.check_to_enable_tax_credit_btn(attrs)
        enrollment = HbxEnrollment.find(attrs[:enrollment_id])
        system_date = TimeKeeper.date_of_record
        # Need to revert the enrollment_due_date with following changes back on 5/1/2020
        # begin_date = Date.new(system_date.year, 11, ::HbxProfile::IndividualEnrollmentDueDayOfMonth + 1).beginning_of_day
        enrollment_due_date = 15
        # Can't create a corresponing enrollment during the end of the year due to overlapping plan year issue and hence disabling the change tax credit button
        begin_date = Date.new(system_date.year, 11, enrollment_due_date + 1).beginning_of_day
        end_date = begin_date.end_of_year.end_of_day
        !((begin_date..end_date).cover?(system_date) && (enrollment.effective_on.year == system_date.year))
      end

      def self.for_post(attrs)
        form = self.new
        unless is_term_or_cancel_date_in_future?(attrs)
          form.errors.add(:base, 'Date cannot be in the past')
          return form
        end
        service = self_term_or_cancel_service(attrs)
        service.term_or_cancel
        form
      end

      def self.for_aptc_update_post(attrs)
        return 'Action cannot be performed because of the overlapping plan years.' unless check_to_enable_tax_credit_btn(attrs)

        service = self_term_or_cancel_service(attrs)
        service.update_aptc
        'Tax credit updated successfully.'
      end

      def self.self_term_or_cancel_service(attrs)
        ::Insured::Services::SelfTermOrCancelService.new(attrs)
      end

      def product
        hbx_enrollment&.product
      end

      def hbx_enrollment
        enrollment&.hbx_enrollment
      end

      def special_enrollment_period
        hbx_enrollment.special_enrollment_period
      end

      def self.is_term_or_cancel_date_in_future?(attrs)
        return true unless attrs[:term_or_cancel] == 'terminate'

        date = Date.strptime(attrs[:term_date], "%m/%d/%Y")
        return date.today? || date.future?
      end
    end
  end
end
