# frozen_string_literal: true

module Notifier
  module EnrollmentHelper
    include Notifier::ConsumerRoleHelper

    def enrollment_hash(enrollment)
      MergeDataModels::Enrollment.new(
        {
          coverage_start_on: enrollment.effective_on,
          coverage_year: enrollment.effective_on.year,
          premium_amount: enrollment.total_premium,
          product: product_hash(enrollment),
          dependents: enrollment_members_hash(enrollment),
          kind: enrollment.kind,
          enrolled_count: enrollment.hbx_enrollment_members.count,
          enrollment_kind: enrollment.enrollment_kind,
          coverage_kind: enrollment.coverage_kind,
          aptc_amount: enrollment.applied_aptc_amount,
          is_receiving_assistance: is_receiving_assistance?(enrollment),
          responsible_amount: responsible_amount(enrollment)
        }
      )
    end

    def product_hash(enrollment)
      product = enrollment.product
      MergeDataModels::Product.new(
        {
          coverage_start_on: product.application_period.min,
          coverage_end_on: product.application_period.max,
          title: product.title,
          metal_level_kind: product.metal_level_kind,
          kind: product.kind,
          issuer_profile_name: product.issuer_profile.legal_name,
          hsa_eligibility: product.hsa_eligibility,
          renewal_plan_type: nil,
          is_csr: product.is_csr?,
          deductible: deductible(enrollment),
          family_deductible: product.family_deductible,
          carrier_phone: phone_number(product.issuer_profile.legal_name)
        }
      )
    end

    def deductible(enrollment)
      enrollment.hbx_enrollment_members.size > 0 ? enrollment.product.family_deductible : enrollment.product.deductible
    end

    def enrollment_members_hash(enrollment)
      enrollment.hbx_enrollment_members.inject([]) do |enrollees, member|
        enrollee = MergeDataModels::Person.new(
          {
            first_name: member.person.first_name.titleize,
            last_name: member.person.last_name.titleize,
            age: member.person.age_on(TimeKeeper.date_of_record)
          }
        )
        enrollees << enrollee
      end
    end

    def responsible_amount(enrollment)
      format_currency((enrollment.total_premium - enrollment.applied_aptc_amount.to_f), 2)
    end

    def is_receiving_assistance?(enrollment)
      enrollment.applied_aptc_amount > 0 || enrollment.product.is_csr?
    end
  end
end