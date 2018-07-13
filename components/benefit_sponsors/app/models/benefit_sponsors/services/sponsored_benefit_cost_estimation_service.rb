module BenefitSponsors
  module Services
    class SponsoredBenefitCostEstimationService

      def calculate_estimates_for_home_display(sponsored_benefit)
        query = ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentsQuery.new(sponsored_benefit.benefit_package.benefit_application, sponsored_benefit).call(::Family, TimeKeeper.date_of_record).lazy.map { |rec| rec["hbx_enrollment_id"] }
        reference_product = sponsored_benefit.reference_product
        benefit_application = sponsored_benefit.benefit_package.benefit_application
        package = sponsored_benefit.product_package
        calculator = HbxEnrollmentListSponsorCostCalculator.new(sponsored_benefit.benefit_sponsorship)
        sponsor_contribution, total, employer_costs = calculator.calculate(sponsored_benefit, query)
        if sponsor_contribution.sponsored_benefit.pricing_determinations.any?
          pd = sponsor_contribution.sponsored_benefit.latest_pricing_determination
          sorted_tiers = pd.pricing_determination_tiers.sort_by { |pdt| pdt.pricing_unit.order }
          tier_costs = pd.pricing_determination_tiers.map do |pdt|
            pdt_total = pdt.price
            pdt_employer = BigDecimal.new((pdt_total * pdt.sponsor_contribution_factor).to_s).round(2)
            BigDecimal.new((pdt_total - pdt_employer).to_s).round(2)
          end
          {
            estimated_total_cost: total,
            estimated_sponsor_exposure: employer_costs,
            estimated_enrollee_minimum: tier_costs.min,
            estimated_enrollee_maximum: tier_costs.max
          }
        else
          lowest_cost_product = package.lowest_cost_product(sponsored_benefit.benefit_package.start_on)
          highest_cost_product = package.highest_cost_product(sponsored_benefit.benefit_package.start_on)
          group_cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeEstimatedCostGroup.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
          sponsored_benefit_with_lowest_cost_product  = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, lowest_cost_product, package)
          sponsored_benefit_with_highest_cost_product = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, highest_cost_product, package)
  
          minimum_cost = sponsored_benefit_with_lowest_cost_product.lazy.map do |mg|
            BigDecimal.new((mg.group_enrollment.product_cost_total - mg.group_enrollment.sponsor_contribution_total).to_s).round(2)
          end.min
  
          maximum_cost = sponsored_benefit_with_highest_cost_product.lazy.map do |mg|
            BigDecimal.new((mg.group_enrollment.product_cost_total - mg.group_enrollment.sponsor_contribution_total).to_s).round(2)
          end.max
          {
            estimated_total_cost: total,
            estimated_sponsor_exposure: employer_costs,
            estimated_enrollee_minimum: minimum_cost,
            estimated_enrollee_maximum: maximum_cost
          }
        end
      end

      def calculate_estimates_for_benefit_display(sponsored_benefit)
        reference_product = sponsored_benefit.reference_product
        benefit_application = sponsored_benefit.benefit_package.benefit_application
        package = sponsored_benefit.product_package
        cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
        sponsor_contribution, total, employer_costs = cost_estimator.calculate(
          sponsored_benefit,
          reference_product,
          package)
        if sponsor_contribution.sponsored_benefit.pricing_determinations.any?
          pd = sponsor_contribution.sponsored_benefit.latest_pricing_determination
          sorted_tiers = pd.pricing_determination_tiers.sort_by { |pdt| pdt.pricing_unit.order }
          tier_costs = pd.pricing_determination_tiers.map do |pdt|
            pdt_total = pdt.price
            pdt_employer = BigDecimal.new((pdt_total * pdt.sponsor_contribution_factor).to_s).round(2)
            BigDecimal.new((pdt_total - pdt_employer).to_s).round(2)
          end
          {
            estimated_total_cost: total,
            estimated_sponsor_exposure: employer_costs,
            estimated_enrollee_minimum: tier_costs.min,
            estimated_enrollee_maximum: tier_costs.max
          }
        else
          lowest_cost_product = package.lowest_cost_product(sponsored_benefit.benefit_package.start_on)
          highest_cost_product = package.highest_cost_product(sponsored_benefit.benefit_package.start_on)
          group_cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeEstimatedCostGroup.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
          sponsored_benefit_with_lowest_cost_product  = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, lowest_cost_product, package)
          sponsored_benefit_with_highest_cost_product = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, highest_cost_product, package)
  
          minimum_cost = sponsored_benefit_with_lowest_cost_product.lazy.map do |mg|
            BigDecimal.new((mg.group_enrollment.product_cost_total - mg.group_enrollment.sponsor_contribution_total).to_s).round(2)
          end.min
  
          maximum_cost = sponsored_benefit_with_highest_cost_product.lazy.map do |mg|
            BigDecimal.new((mg.group_enrollment.product_cost_total - mg.group_enrollment.sponsor_contribution_total).to_s).round(2)
          end.max
  
          {
            estimated_total_cost: total,
            estimated_sponsor_exposure: employer_costs,
            estimated_enrollee_minimum: minimum_cost,
            estimated_enrollee_maximum: maximum_cost
          }
        end
      end

      def calculate_employee_estimates_for_package_design(benefit_application, sponsored_benefit, reference_product, package)
        calculate_employee_estimates_for_package_action(benefit_application, sponsored_benefit, reference_product, package, build_objects: true)
      end  
      
      def calculate_employee_estimates_for_package_edit(benefit_application, sponsored_benefit, reference_product, package)
        calculate_employee_estimates_for_package_action(benefit_application, sponsored_benefit, reference_product, package, build_objects: false)
      end

      def calculate_estimates_for_package_design(benefit_application, sponsored_benefit, reference_product, package)
        calculate_estimates_for_package_action(benefit_application, sponsored_benefit, reference_product, package, build_objects: true)
      end

      def calculate_estimates_for_package_edit(benefit_application, sponsored_benefit, reference_product, package)
        calculate_estimates_for_package_action(benefit_application, sponsored_benefit, reference_product, package, build_objects: false)
      end

      protected

      def calculate_employee_estimates_for_package_action(benefit_application, sponsored_benefit, reference_product, package, build_objects: false)
        cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
        sponsor_contribution, total, employer_costs = cost_estimator.calculate(
          sponsored_benefit,
          reference_product,
          package,
          rebuild_sponsor_contribution: false,
          build_new_pricing_determination: build_objects)
        if sponsor_contribution.sponsored_benefit.pricing_determinations.any?
          pd = sponsor_contribution.sponsored_benefit.latest_pricing_determination
          sorted_tiers = pd.pricing_determination_tiers.sort_by { |pdt| pdt.pricing_unit.order }
          tier_costs = pd.pricing_determination_tiers.lazy.map do |pdt|
            pdt_total = pdt.price
            pdt_employer = BigDecimal.new((pdt_total * pdt.sponsor_contribution_factor).to_s).round(2)
            BigDecimal.new((pdt_total - pdt_employer).to_s).round(2)
          end
          lowest_cost = tier_costs.min
          highest_cost = tier_costs.max
          group_cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeEstimatedCostGroup.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
          sponsored_benefit_with_reference_product = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, reference_product, package)
          sponsored_benefit_with_reference_product.map do |estimate|
            main_name = estimate.primary_member.census_member.full_name
            dep_count = estimate.members.count - 1
            {
              name: main_name,
              dependent_count: dep_count,
              highest_cost_estimate: highest_cost,
              lowest_cost_estimate: lowest_cost,
              reference_estimate: employee_cost_from_group_enrollment(estimate.group_enrollment)
            }
          end
        else
          lowest_cost_product = package.lowest_cost_product(benefit_application.start_on)
          highest_cost_product = package.highest_cost_product(benefit_application.start_on)
          group_cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeEstimatedCostGroup.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)

          sponsored_benefit_with_lowest_cost_product  = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, lowest_cost_product, package)
          sponsored_benefit_with_highest_cost_product = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, highest_cost_product, package)
          sponsored_benefit_with_reference_product    = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, reference_product, package)
          all_estimates = sponsored_benefit_with_lowest_cost_product + sponsored_benefit_with_highest_cost_product + sponsored_benefit_with_reference_product
          grouped_estimates = all_estimates.group_by do |estimate|
            estimate.group_id
          end
          grouped_estimates.values.map do |estimate_set|
            reference_record = estimate_set.first
            main_name = reference_record.primary_member.census_member.full_name
            dep_count = reference_record.members.count - 1
            ref_estimate = estimate_set.map(&:group_enrollment).detect do |ge|
                             ge.product.id == reference_product.id
                           end
            low_estimate = estimate_set.map(&:group_enrollment).detect do |ge|
                             ge.product.id == lowest_cost_product.id
                           end
            high_estimate = estimate_set.map(&:group_enrollment).detect do |ge|
                             ge.product.id == highest_cost_product.id
                           end
            {
              name: main_name,
              dependent_count: dep_count,
              highest_cost_estimate: employee_cost_from_group_enrollment(high_estimate),
              lowest_cost_estimate: employee_cost_from_group_enrollment(low_estimate),
              reference_estimate: employee_cost_from_group_enrollment(ref_estimate)
            }
          end
        end
      end

      def calculate_estimates_for_package_action(benefit_application, sponsored_benefit, reference_product, package, build_objects: false)
        cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
        sponsor_contribution, total, employer_costs = cost_estimator.calculate(
          sponsored_benefit,
          reference_product,
          package,
          rebuild_sponsor_contribution: false,
          build_new_pricing_determination: build_objects)
        if sponsor_contribution.sponsored_benefit.pricing_determinations.any?
          pd = sponsor_contribution.sponsored_benefit.latest_pricing_determination
          sorted_tiers = pd.pricing_determination_tiers.sort_by { |pdt| pdt.pricing_unit.order }
          tier_costs = pd.pricing_determination_tiers.lazy.map do |pdt|
            pdt_total = pdt.price
            pdt_employer = BigDecimal.new((pdt_total * pdt.sponsor_contribution_factor).to_s).round(2)
            BigDecimal.new((pdt_total - pdt_employer).to_s).round(2)
          end
          {
            estimated_total_cost: total,
            estimated_sponsor_exposure: employer_costs,
            estimated_enrollee_minimum: tier_costs.min,
            estimated_enrollee_maximum: tier_costs.max
          }
        else
          lowest_cost_product = package.lowest_cost_product(benefit_application.start_on)
          highest_cost_product = package.highest_cost_product(benefit_application.start_on)
          group_cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeEstimatedCostGroup.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
          sponsored_benefit_with_lowest_cost_product  = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, lowest_cost_product, package)
          sponsored_benefit_with_highest_cost_product = group_cost_estimator.calculate(sponsor_contribution.sponsored_benefit, highest_cost_product, package)
  
          minimum_cost = sponsored_benefit_with_lowest_cost_product.lazy.map do |mg|
            BigDecimal.new((mg.group_enrollment.product_cost_total - mg.group_enrollment.sponsor_contribution_total).to_s).round(2)
          end.min
  
          maximum_cost = sponsored_benefit_with_highest_cost_product.lazy.map do |mg|
            BigDecimal.new((mg.group_enrollment.product_cost_total - mg.group_enrollment.sponsor_contribution_total).to_s).round(2)
          end.max
  
          {
            estimated_total_cost: total,
            estimated_sponsor_exposure: employer_costs,
            estimated_enrollee_minimum: minimum_cost,
            estimated_enrollee_maximum: maximum_cost
          }
        end
      end

      def employee_cost_from_group_enrollment(group_enrollment)
        BigDecimal.new((group_enrollment.product_cost_total - group_enrollment.sponsor_contribution_total).to_s).round(2)
      end
    end
  end
end