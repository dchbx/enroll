# frozen_string_literal: true

module Insured
  module Factories
    class SelfServiceFactory
      extend ::FloatHelper
      include ::FloatHelper
      extend Acapi::Notifiers
      attr_accessor :document_id, :enrollment_id, :family_id, :product_id, :qle_id, :sep_id

      def initialize(args)
        self.document_id   = args[:document_id] || nil
        self.enrollment_id = args[:enrollment_id] || nil
        self.family_id     = args[:family_id] || nil
        self.product_id    = args[:product_id] || nil
        self.qle_id        = args[:qle_id] || nil
        self.sep_id        = args[:sep_id] || nil
      end

      def self.find(enrollment_id, family_id)
        new({enrollment_id: enrollment_id, family_id: family_id}).build_form_params
      end

      def self.term_or_cancel(enrollment_id, term_date, term_or_cancel)
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
        enrollment.term_or_cancel_enrollment(enrollment, term_date)
        return unless term_or_cancel == 'cancel'

        transmit_flag = true
        notify(
          "acapi.info.events.hbx_enrollment.terminated",
          {
            :reply_to => "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler",
            "hbx_enrollment_id" => @enrollment_id,
            "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
            "is_trading_partner_publishable" => transmit_flag
          }
        )
      end

      def self.update_aptc(enrollment_id, applied_aptc_amount)
        # field :elected_aptc_pct, type: Float, default: 0.0
        # field :applied_aptc_amount, type: Money, default: 0.0
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))

        new_effective_date = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date
        reinstatement = Enrollments::Replicator::Reinstatement.new(enrollment, new_effective_date, applied_aptc_amount).build
        reinstatement.save!
        update_enrollment_for_apcts(reinstatement, applied_aptc_amount)

        reinstatement.select_coverage!
      end

      def self.update_enrollment_for_apcts(reinstatement, applied_aptc_amount)
        applicable_aptc_by_member = member_level_aptc_breakdown(reinstatement, applied_aptc_amount)
        cost_decorator = UnassistedPlanCostDecorator.new(reinstatement.product, reinstatement, applied_aptc_amount)
        reinstatement.hbx_enrollment_members.each do |enrollment_member|
          member_aptc_value = applicable_aptc_by_member[enrollment_member.applicant_id.to_s]
          next enrollment_member unless member_aptc_value
          member_ehb_premium = cost_decorator.member_ehb_premium(enrollment_member)

          if member_aptc_value > member_ehb_premium
            member_aptc_value = round_down_float_two_decimals(member_aptc_value)
          else
            member_aptc_value
          end

          enrollment_member.update_attributes!(applied_aptc_amount: member_aptc_value)
        end

        eli_fac_obj = ::Factories::EligibilityFactory.new(reinstatement.id, reinstatement.effective_on)
        max_applicable_aptc = eli_fac_obj.fetch_max_aptc
        reinstatement.update_attributes!(elected_aptc_pct: applied_aptc_amount / max_applicable_aptc, applied_aptc_amount: cost_decorator.total_aptc_amount)
      end

      def self.member_level_aptc_breakdown(new_enrollment, applied_aptc_amount)
        applicable_aptc = fetch_applicable_aptc(new_enrollment, applied_aptc_amount)
        eli_fac_obj = ::Factories::EligibilityFactory.new(new_enrollment.id, new_enrollment.effective_on)
        eli_fac_obj.fetch_member_level_applicable_aptcs(applicable_aptc)
      end

      def self.fetch_applicable_aptc(new_enrollment, selected_aptc, excluding_enrollment_id = nil)
        service = ::Services::ApplicableAptcService.new(new_enrollment.id, new_enrollment.effective_on, selected_aptc, [new_enrollment.product_id], excluding_enrollment_id)
        service.applicable_aptcs[new_enrollment.product_id.to_s]
      end

      def is_aptc_eligible(enrollment, family)
        return false if enrollment.kind == "coverall" || enrollment.coverage_kind == "dental"

        allowed_metal_levels = ["platinum", "silver", "gold", "bronze"]
        product = enrollment.product
        if family.active_household.latest_active_tax_household.present?
          tax_household = family.active_household.latest_active_tax_household
          aptc_members = tax_household.aptc_members if tax_household.present?
          true if allowed_metal_levels.include?(product.metal_level_kind.to_s) && enrollment.household.tax_households.present? && aptc_members.present?
        else
          false
        end
      end

      def build_form_params
        new_effective_on          = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date
        enrollment                = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
        family                    = Family.find(BSON::ObjectId.from_string(family_id))
        sep                       = SpecialEnrollmentPeriod.find(BSON::ObjectId.from_string(family.latest_active_sep.id)) if family.latest_active_sep.present?
        qle                       = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))  if sep.present?
        available_aptc            = calculate_max_applicable_aptc(enrollment, new_effective_on)
        elected_aptc_pct          = calculate_elected_aptc_pct(enrollment, available_aptc)
        default_tax_credit_value  = default_tax_credit_value(enrollment, available_aptc)
        {
          enrollment: enrollment,
          family: family,
          qle: qle,
          is_aptc_eligible: is_aptc_eligible(enrollment, family),
          new_effective_on: new_effective_on,
          available_aptc: available_aptc,
          default_tax_credit_value: default_tax_credit_value,
          elected_aptc_pct: elected_aptc_pct,
          new_enrollment_premium: new_enrollment_premium(default_tax_credit_value, enrollment)
        }
      end

      def calculate_max_applicable_aptc(enrollment, new_effective_on)
        selected_aptc = ::Services::AvailableEligibilityService.new(enrollment.id, new_effective_on, enrollment.id).available_eligibility[:total_available_aptc]
        Insured::Factories::SelfServiceFactory.fetch_applicable_aptc(enrollment, selected_aptc, enrollment.id)
      end

      def self.find_enrollment_effective_on_date(hbx_created_datetime, current_enrollment_effective_on)
        day = 1
        hour = hbx_created_datetime.hour
        min = hbx_created_datetime.min
        sec = hbx_created_datetime.sec
        # this condition is for self service APTC feature ONLY.
        if current_enrollment_effective_on.year != hbx_created_datetime.year
          condition = (Date.new(hbx_created_datetime.year, 11, 1)..Date.new(hbx_created_datetime.year, 12, 15)).include?(hbx_created_datetime.to_date)
          offset_month = condition ? 0 : 1
          year = current_enrollment_effective_on.year
          month = current_enrollment_effective_on.month + offset_month
        else
          offset_month = hbx_created_datetime.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth ? 1 : 2
          year = hbx_created_datetime.year
          month = hbx_created_datetime.month + offset_month
        end
        if month > 12
          year += 1
          month -= 12
        end
        DateTime.new(year, month, day, hour, min, sec)
      end

      private

      def default_tax_credit_value(enrollment, available_aptc)
        enrollment.applied_aptc_amount.to_f > available_aptc ? available_aptc : enrollment.applied_aptc_amount.to_f
      end

      def calculate_elected_aptc_pct(enrollment, available_aptc)
        pct = float_fix(enrollment.applied_aptc_amount.to_f / available_aptc).round(2)
        pct > 1 ? 1 : pct
      end

      def new_enrollment_premium(default_tax_credit_value, enrollment)
        float_fix(enrollment.total_premium - default_tax_credit_value)
      end

    end
  end
end
