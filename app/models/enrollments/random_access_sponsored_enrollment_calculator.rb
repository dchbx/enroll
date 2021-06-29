# frozen_string_literal: true

module Enrollments
  # Used when bulk-reporting enrollment calculations but the order in which
  # enrollments will be placed or grouped can not be predicted.
  # It allows passing in a number of cache hashes that allow you to look up
  # what would normally be queried from the database as needed.
  class RandomAccessSponsoredEnrollmentCalculator
    PreviousProductSlug = Struct.new(:id)

    EnrollmentMemberAdapter = Struct.new(:member_id, :dob, :relationship, :is_primary_member, :is_disabled) do
      def is_disabled?
        is_disabled
      end

      def is_primary_member?
        is_primary_member
      end
    end

    def initialize(
      original_enrollment,
      family_member_person_cache = {},
      rel_cache = {},
      sponsored_benefit_cache = {},
      rating_area_cache = {}
    )
      @original_enrollment = original_enrollment
      @family_member_person_cache = family_member_person_cache
      @relationship_cache = rel_cache
      @rating_area_cache = rating_area_cache
      @sponsored_benefit = if sponsored_benefit_cache.key?(@original_enrollment.sponsored_benefit_id)
                             sponsored_benefit_cache[@original_enrollment.sponsored_benefit_id]
                           else
                             @original_enrollment.sponsored_benefit
                           end
      @member_group = as_shop_member_group
      @pricing_model = @sponsored_benefit.pricing_model
      @contribution_model = @sponsored_benefit.contribution_model
      @pricing_calculator = @sponsored_benefit.pricing_calculator
      @contribution_calculator = @sponsored_benefit.contribution_calculator
      @sponsor_contribution = @sponsored_benefit.sponsor_contribution
    end

    def groups_for_products(products)
      @groups_for_products ||= calculate_groups_for_products(products)
    end

    protected

    def calculate_groups_for_products(products)
      products.map do |product|
        member_group_with_product = @member_group.clone_for_coverage(product)
        member_group_with_pricing = @pricing_calculator.calculate_price_for(@pricing_model, member_group_with_product, @sponsor_contribution)
        @contribution_calculator.calculate_contribution_for(@contribution_model, member_group_with_pricing, @sponsor_contribution)
      end
    end

    def as_shop_member_group
      roster_members = []
      group_enrollment_members = []
      previous_enrollment = @original_enrollment.parent_enrollment
      previous_product = nil
      previous_product = PreviousProductSlug.new(previous_enrollment.product_id) if previous_enrollment

      subscriber = @original_enrollment.hbx_enrollment_members.detect(&:is_subscriber?)

      rating_area = if @rating_area_cache.key?(@original_enrollment.rating_area_id)
                      @rating_area_cache[@original_enrollment.rating_area_id]
                    else
                      @original_enrollment.rating_area
                    end

      @original_enrollment.hbx_enrollment_members.each do |hem|
        person = if @family_member_person_cache.key?(hem.applicant_id)
                   @family_member_person_cache[hem.applicant_id]
                 else
                   hem.person
                 end

        rel_value = if hem.is_subscriber?
                      "self"
                    elsif @relationship_cache.key?([hem.applicant_id, subscriber.applicant_id])
                      @relationship_cache[[hem.applicant_id, subscriber.applicant_id]]
                    else
                      hem.primary_relationship
                    end
        roster_member = EnrollmentMemberAdapter.new(
          hem.id,
          person.dob,
          rel_value,
          hem.is_subscriber?,
          person.is_disabled
        )
        roster_members << roster_member
        group_enrollment_member = BenefitSponsors::Enrollments::MemberEnrollment.new({
                                                                                       member_id: hem.id,
                                                                                       coverage_eligibility_on: hem.coverage_start_on
                                                                                     })
        group_enrollment_members << group_enrollment_member
      end
      group_enrollment = BenefitSponsors::Enrollments::GroupEnrollment.new(
        previous_product: previous_product,
        coverage_start_on: @original_enrollment.effective_on,
        member_enrollments: group_enrollment_members,
        rate_schedule_date: @sponsored_benefit.rate_schedule_date,
        rating_area: rating_area.exchange_provided_code,
        sponsor_contribution_prohibited: @original_enrollment.is_cobra_status?
      )
      BenefitSponsors::Members::MemberGroup.new(
        roster_members,
        group_id: @original_enrollment.id,
        group_enrollment: group_enrollment
      )
    end
  end
end