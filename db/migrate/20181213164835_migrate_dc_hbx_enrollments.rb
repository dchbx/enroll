# frozen_string_literal: true

class MigrateDcHbxEnrollments < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"
      @logger = Logger.new("#{Rails.root}/log/enrollment_migration_data.log") unless Rails.env.test?
      @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      update_hbx_enrollments

      @logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down; end

  private

  def self.update_hbx_enrollments
    say_with_time("Time taken to build data hash") do

      @benefit_app_hash = {}
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications.exists => true).each do |bs|
        bs.benefit_applications.each do |ba|

          ba.benefit_packages.unscoped.each do |bg|
            plan_year = PlanYear.find(ba.id)
            raise "Plan year not found" unless plan_year.present?
            old_bg = plan_year.benefit_groups.unscoped.where(title: bg.title)
            raise "Issue with benefit group" unless old_bg.present? || old_bg.count > 1
            bg_hash = {}
            bg_hash[old_bg.first.id] = {'benefit_package_id' => bg.id, 'benefit_sponsorship_id' => bs.id,'health_sponsored_benefit_id' => bg.health_sponsored_benefit.id, "rating_area_id" => ba.recorded_rating_area_id}
            bg_hash[old_bg.first.id].merge!({'dental_sponsored_benefit_id' => bg.dental_sponsored_benefit.id }) if bg.dental_sponsored_benefit.present?
            @benefit_app_hash.merge!(bg_hash)
          end
        rescue StandardError => e
          print 'F' unless Rails.env.test?
          unless Rails.env.test?
            @logger.error "Plan Year not found #{ba.id},
              #{e.message}"
            end

        end
      end

      @plan_to_product_hash = {aca_shop: {}, aca_individual: {}, fehb: {}}

      BenefitMarkets::Products::Product.aca_shop_market.each do |product|
        plan_hash = {}
        hios_id = product.hios_id
        year = product.active_year
        plan = Plan.where(hios_id: hios_id, active_year: year, market: "shop").first
        plan_hash[plan.id] = {"product_id" => product.id, "carrier_profile_id" => product.issuer_profile_id}
        @plan_to_product_hash[:aca_shop].merge!(plan_hash)
      end

      BenefitMarkets::Products::Product.aca_individual_market.each do |product|
        plan_hash = {}
        hios_id = product.hios_id
        year = product.active_year
        plan = Plan.where(hios_id: hios_id, active_year: year, market: "individual").first
        plan_hash[plan.id] = {"product_id" => product.id, "carrier_profile_id" => product.issuer_profile_id}
        @plan_to_product_hash[:aca_individual].merge!(plan_hash)
      end

      BenefitMarkets::Products::Product.where(benefit_market_kind: :fehb).each do |product|
        plan_hash = {}
        hios_id = product.hios_id
        year = product.active_year
        plan = Plan.where(hios_id: hios_id, active_year: year, market: "shop", metal_level: 'gold').first
        plan_hash[plan.id] = {"product_id" => product.id, "carrier_profile_id" => product.issuer_profile_id}
        @plan_to_product_hash[:fehb].merge!(plan_hash)
      end
    end

    # say_with_time("Time taken to migrate enrollments") do
    #   f_count = Family.where(:'households.hbx_enrollments'.exists=>true).count
    #   offset_count = 0
    #   limit_count = 1000
    #   ivl_plan_hash = @plan_to_product_hash[:aca_individual]
    #   fehb_plan_hash = @plan_to_product_hash[:fehb]
    #   shop_plan_hash = @plan_to_product_hash[:aca_shop]
    #
    #   while (offset_count <= f_count) do
    #     puts "offset_count: #{offset_count}"
    #     Family.where(:'households.hbx_enrollments'.exists=>true).limit(limit_count).offset(offset_count).each do |fam|
    #       begin
    #         fam.active_household.hbx_enrollments.each do |hbx|
    #           next if hbx.shopping?
    #
    #           if hbx.benefit_group_id.present?
    #             plan_hash = shop_plan_hash
    #             product_data = plan_hash[hbx.plan_id]
    #             benefit_app_data = @benefit_app_hash[hbx.benefit_group_id]
    #
    #             if benefit_app_data
    #               hbx.update_attributes(
    #                   product_id: product_data ? product_data['product_id'] : nil,
    #                   issuer_profile_id: product_data ? product_data['carrier_profile_id'] : nil,
    #                   benefit_sponsorship_id: benefit_app_data['benefit_sponsorship_id'],
    #                   sponsored_benefit_package_id: benefit_app_data['benefit_package_id'],
    #                   sponsored_benefit_id: hbx.coverage_kind == "health" ? benefit_app_data['health_sponsored_benefit_id'] : benefit_app_data['dental_sponsored_benefit_id'],
    #                   rating_area_id: benefit_app_data["rating_area_id"]
    #               )
    #               print '.' unless Rails.env.test?
    #             else
    #               print 'F' unless Rails.env.test?
    #               @logger.error "benefit application reference not found enrollment: #{hbx.hbx_id} --- #{hbx.aasm_state} --- #{hbx.try(:employer_profile).try(:hbx_id)} --- #{hbx.try(:employer_profile).try(:legal_name)}"
    #             end
    #           else
    #             product_data = ivl_plan_hash[hbx.plan_id]
    #             hbx.update_attributes(
    #                 product_id: product_data['product_id'], issuer_profile_id: product_data['carrier_profile_id']
    #             )
    #             print '.' unless Rails.env.test?
    #           end
    #         end
    #       rescue => e
    #         print 'F' unless Rails.env.test?
    #         @logger.error "Update failed for enrollment family id: #{fam.id},
    #         #{e.message}" unless Rails.env.test?
    #       end
    #     end
    #     offset_count += limit_count
    #   end
    #
    #   # update congress product id
    #   BenefitSponsors::Organizations::Organization.where(:"profiles._type" => /.*FehbEmployerProfile$/).each do |org|
    #     org.active_benefit_sponsorship.census_employees.unscoped.each do |ce|
    #       ce.benefit_group_assignments.each do |bga|
    #         get_hbx_enrollments(bga).each do |hbx|
    #           next if hbx.shopping?
    #           product_data = fehb_plan_hash[hbx.plan_id]
    #           hbx.update_attributes(
    #               product_id: product_data ? product_data['product_id'] : nil,
    #               issuer_profile_id: product_data ? product_data['carrier_profile_id'] : nil
    #           )
    #           print '.' unless Rails.env.test?
    #         end
    #       end
    #     end
    #   end
    # end

    say_with_time("Migrate enrollments to it's own collection") do
      Family.collection.aggregate([
        {"$unwind" => "$households"},
        {"$unwind" => "$households.hbx_enrollments"},
        {"$project" => {_id: "$households.hbx_enrollments._id",
                        family_id: "$_id",
                        household_id: "$households._id",
                        updated_by_id: "$households.hbx_enrollments.updated_by_id",
                        created_at: "$households.hbx_enrollments.created_at",
                        updated_at: "$households.hbx_enrollments.updated_at",
                        is_any_enrollment_member_outstanding: "$households.hbx_enrollments.is_any_enrollment_member_outstanding",
                        coverage_household_id: "$households.hbx_enrollments.coverage_household_id",
                        kind: "$households.hbx_enrollments.kind",
                        enrollment_kind: "$households.hbx_enrollments.enrollment_kind",
                        coverage_kind: "$households.hbx_enrollments.coverage_kind",
                        elected_amount: "$households.hbx_enrollments.elected_amount",
                        elected_premium_credit: "$households.hbx_enrollments.elected_premium_credit",
                        applied_premium_credit: "$households.hbx_enrollments.applied_premium_credit",
                        elected_aptc_pct: "$households.hbx_enrollments.elected_aptc_pct",
                        applied_aptc_amount: "$households.hbx_enrollments.applied_aptc_amount",
                        changing: "$households.hbx_enrollments.changing",
                        effective_on: "$households.hbx_enrollments.effective_on",
                        terminated_on: "$households.hbx_enrollments.terminated_on",
                        terminate_reason: "$households.hbx_enrollments.terminate_reason",
                        broker_agency_profile_id: "$households.hbx_enrollments.broker_agency_profile_id",
                        writing_agent_id: "$households.hbx_enrollments.writing_agent_id",
                        employee_role_id: "$households.hbx_enrollments.employee_role_id",
                        benefit_group_id: "$households.hbx_enrollments.benefit_group_id",
                        benefit_group_assignment_id: "$households.hbx_enrollments.benefit_group_assignment_id",
                        hbx_id: "$households.hbx_enrollments.hbx_id",
                        special_enrollment_period_id: "$households.hbx_enrollments.special_enrollment_period_id",
                        predecessor_enrollment_id: "$households.hbx_enrollments.predecessor_enrollment_id",
                        enrollment_signature: "$households.hbx_enrollments.enrollment_signature",
                        consumer_role_id: "$households.hbx_enrollments.consumer_role_id",
                        resident_role_id: "$households.hbx_enrollments.resident_role_id",
                        plan_id: "$households.hbx_enrollments.plan_id",
                        carrier_profile_id: "$households.hbx_enrollments.carrier_profile_id",
                        benefit_package_id: "$households.hbx_enrollments.benefit_package_id",
                        benefit_coverage_period_id: "$households.hbx_enrollments.benefit_coverage_period_id",
                        benefit_sponsorship_id: "$households.hbx_enrollments.benefit_sponsorship_id",
                        sponsored_benefit_package_id: "$households.hbx_enrollments.sponsored_benefit_package_id",
                        sponsored_benefit_id: "$households.hbx_enrollments.sponsored_benefit_id",
                        rating_area_id: "$households.hbx_enrollments.rating_area_id",
                        product_id: "$households.hbx_enrollments.product_id",
                        issuer_profile_id: "$households.hbx_enrollments.issuer_profile_id",
                        original_application_type: "$households.hbx_enrollments.original_application_type",
                        submitted_at: "$households.hbx_enrollments.submitted_at",
                        aasm_state: "$households.hbx_enrollments.aasm_state",
                        aasm_state_date: "$households.hbx_enrollments.aasm_state_date",
                        updated_by: "$households.hbx_enrollments.updated_by",
                        is_active: "$households.hbx_enrollments.is_active",
                        waiver_reason: "$households.hbx_enrollments.waiver_reason",
                        published_to_bus_at: "$households.hbx_enrollments.published_to_bus_at",
                        review_status: "$households.hbx_enrollments.review_status",
                        special_verification_period: "$households.hbx_enrollments.special_verification_period",
                        termination_submitted_on: "$households.hbx_enrollments.termination_submitted_on",
                        checkbook_url: "$households.hbx_enrollments.checkbook_url",
                        external_enrollment: "$households.hbx_enrollments.external_enrollment",
                        version: "$households.hbx_enrollments.version",
                        modifier_id: "$households.hbx_enrollments.modifier_id",
                        workflow_state_transitions: "$households.hbx_enrollments.workflow_state_transitions",
                        hbx_enrollment_members: "$households.hbx_enrollments.hbx_enrollment_members",
                        comments: "$households.hbx_enrollments.comments"}},
        {"$out" => "hbx_enrollments"}
    ]).each
    end

    HbxEnrollment.skip_callback(:save, :after, :notify_on_save,  raise: false)
    say_with_time("Update enrollment with benefit application reference's ") do
      HbxEnrollment.create_indexes
      @benefit_app_hash.each do |benefit_hash|
        HbxEnrollment.where(benefit_group_id: benefit_hash[0], coverage_kind: 'health')
                     .update_all(benefit_sponsorship_id: benefit_hash[1]['benefit_sponsorship_id'],
                                 sponsored_benefit_package_id: benefit_hash[1]['benefit_package_id'],
                                 rating_area_id: benefit_hash[1]["rating_area_id"],
                                 sponsored_benefit_id: benefit_hash[1]['health_sponsored_benefit_id'])

        HbxEnrollment.where(benefit_group_id: benefit_hash[0], coverage_kind: 'dental')
                     .update_all(sponsored_benefit_id: benefit_hash[1]['dental_sponsored_benefit_id'],
                                 benefit_sponsorship_id: benefit_hash[1]['benefit_sponsorship_id'],
                                 sponsored_benefit_package_id: benefit_hash[1]['benefit_package_id'],
                                 rating_area_id: benefit_hash[1]["rating_area_id"])
      end
    end

    say_with_time("Update enrollment with product ids ") do
      ivl_plan_hash = @plan_to_product_hash[:aca_individual]
      fehb_plan_hash = @plan_to_product_hash[:fehb]
      shop_plan_hash = @plan_to_product_hash[:aca_shop]
      benefit_sponsorship_ids = BenefitSponsors::Organizations::Organization.where(:"profiles._type" => /.*FehbEmployerProfile/).map(&:active_benefit_sponsorship).map(&:_id)

      ivl_plan_hash.each do |product_data|
        HbxEnrollment.where(plan_id: product_data[0]).update_all(product_id: product_data[1]['product_id'], issuer_profile_id: product_data[1]['carrier_profile_id'])
      end

      shop_plan_hash.each do |product_data|
        HbxEnrollment.where(plan_id: product_data[0]).update_all(product_id: product_data[1]['product_id'], issuer_profile_id: product_data[1]['carrier_profile_id'])
      end

      fehb_plan_hash.each do |product_data|
        HbxEnrollment.where(:benefit_sponsorship_id.in => benefit_sponsorship_ids, plan_id: product_data[0]).update_all(product_id: product_data[1]['product_id'], issuer_profile_id: product_data[1]['carrier_profile_id'])
      end
    end
    HbxEnrollment.set_callback(:save, :after, :notify_on_save,  raise: false)

    reset_hash
  end

  # def self.get_hbx_enrollments(bga)
  #   bga.covered_families.inject([]) do |enrollments, family|
  #     family.households.each do |household|
  #       enrollments += household.hbx_enrollments.select do |enrollment|
  #         enrollment.benefit_group_assignment_id == bga.id
  #       end.to_a
  #     end
  #     enrollments
  #   end
  # end

  def self.reset_hash
    @plan_to_product_hash = {}
    @benefit_app_hash = {}
  end

end