# frozen_string_literal: true

module Insured
  module Factories
    class SelfServiceFactory
      attr_accessor :document_id, :enrollment_id, :family_id, :product_id, :qle_id, :sep_id
      extend Acapi::Notifiers

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

      def is_aptc_eligible(enrollment, family)
        return false if enrollment.kind == "coverall" || enrollment.coverage_kind == "dental"
        
        allowed_metal_levels = ["platinum", "silver", "gold", "bronze"]
        product = enrollment.product
        tax_household = family.active_household.latest_active_tax_household if family.active_household.latest_active_tax_household.present?
        aptc_members = tax_household.aptc_members if tax_household.present?
        true if allowed_metal_levels.include?(product.metal_level_kind.to_s) && enrollment.household.tax_households.present? && aptc_members.present?
      end

      def build_form_params
        enrollment = HbxEnrollment.find(BSON::ObjectId.from_string(enrollment_id))
        family     = Family.find(BSON::ObjectId.from_string(family_id))
        sep        = SpecialEnrollmentPeriod.find(BSON::ObjectId.from_string(family.latest_active_sep.id)) if family.latest_active_sep.present?
        qle        = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))  if sep.present?
        { enrollment: enrollment, family: family, qle: qle, is_aptc_eligible: is_aptc_eligible(enrollment, family) }
      end

    end
  end
end
