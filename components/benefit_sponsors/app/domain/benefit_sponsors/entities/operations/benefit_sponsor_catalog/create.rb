require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Entities
    module Operations
      module BenefitSponsorCatalog
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        class Create

          attr_reader :benefit_sponsorship, :effective_date

          def call(benefit_sponsorship, effective_date)
            @benefit_sponsorship = benefit_sponsorship
            @effective_date = effective_date

            # entity_attributes       = yield extract_attributes(sponosor_eligibility, contribution_model)
            # result                  = yield validate(entity_attributes)
            sponsor_catalog = yield build(attributes)
            sponsor_catalog = yield validate(sponsor_catalog)
            sponsor_catalog = yield assign_default_contribution_model(sponsor_catalog)
            sponsor_catalog = yield create(sponsor_catalog)

            Success(sponsor_catalog)
          end

          # def extract_attributes(sponosor_eligibility, contribution_model)
          #   attrs = {
          #     effective_date: sponsor_eligibility[:effective_date],
          #     benefit_type: sponsor_eligibility[:benefit_type],
          #     exception_granted: sponsor_eligibility[:flexibile_contribution_model_enabled],
          #     contribution_model: contribution_model.attributes.slice(:_id, :contribution_type, :effective_period, :eligibility_policies)
          #   }

          #   Success(attrs)
          # end

          # def validate(input)
          #   contract = BenefitMarkets::Entities::Validators::SponsorContributionModelCriteriaContract.new
          #   Success(contract.call(input))
          # end

          def build
            benefit_market = benefit_sponsorship.benefit_market
            benefit_sponsor_catalog = benefit_market.benefit_sponsor_catalog_for(benefit_sponsorship.recorded_service_areas, effective_date)
            
            Success(benefit_sponsor_catalog)
          end
          
          def assign_default_contribution_model(benefit_sponsor_catalog)
            enrollment_eligibility = benefit_sponsorship.enrollment_eligibility_for(effective_date)
            business_policy = business_policy_for(benefit_sponsor_catalog, enrollment_eligibility)
            contribution_model_title = business_policy.policy_result.to_s.humanize.titleize

            benefit_sponsor_catalog.product_packages.each do |product_package|
              product_package.assigned_contribution_model = product_package.contribution_models.detect do |cm|
                cm.title == contribution_model_title
              end
            end

            Success(contribution_model_criteria)
          end

          private

          def business_policy_for(benefit_sponsor_catalog, enrollment_eligibility)
            eligibility_policy = benefit_sponsor_catalog.enrollment_eligibility_policy
            policies = eligibility_policy.business_policies_for(:create_application)
            policies.detect{|business_policy| business_policy.is_satisfied?(enrollment.eligibility)}
          end
        end
      end
    end
  end
end