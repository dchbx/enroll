# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitApplications
      # This class clones a benefit_application where end
      # result is a new benefit_application. The aasm_state
      # of the newly created application will be draft irrespective
      # of the aasm_state of the input benefit_application.
      # Also, the result benefit_application is a non-persisted object.
      class Clone
        include Dry::Monads[:result, :do]

        # @param [ BenefitSponsors::BenefitApplications::BenefitApplication ] benefit_application
        # @param [ Date ] effective_period for new benefit_application
        # @return [ BenefitSponsors::BenefitApplications::BenefitApplication ] benefit_application
        def call(params)
          values              = yield validate(params)
          ba_params           = yield construct_params(values)
          ba_entity           = yield build_benefit_application(ba_params)
          benefit_application = yield clone_benefit_application(ba_entity, values)

          Success(benefit_application)
        end

        private

        def validate(params)
          return Failure('Missing Keys.') unless params.key?(:benefit_application) && params.key?(:effective_period)
          return Failure('Not a valid Benefit Application object.') unless params[:benefit_application].is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)
          return Failure('Invalid effective_period') if params[:effective_period].min > params[:effective_period].max

          Success(params)
        end

        def construct_params(values)
          current_ba = values[:benefit_application]
          ba_params = current_ba.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :reinstated_id, :terminated_on, :termination_kind, :termination_reason, :benefit_packages, :workflow_state_transitions)
          ba_params.merge!({aasm_state: :draft, effective_period: values[:effective_period]})
          ba_params[:benefit_packages] = benefit_packages_params(current_ba)
          Success(ba_params)
        end

        def benefit_packages_params(current_ba)
          current_ba.benefit_packages.inject([]) do |bps_array, bp|
            bp_params = bp.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :sponsored_benefits)
            bp_params[:sponsored_benefits] = sponsored_benefits_params(bp)
            bps_array << bp_params
          end
        end

        def sponsored_benefits_params(current_bp)
          current_bp.sponsored_benefits.inject([]) do |sbs_array, sb|
            sb_params = sb.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :sponsor_contribution, :pricing_determinations, :reference_product)
            sb_params[:product_kind] = sb.product_kind
            sb_params[:sponsor_contribution] = sponsor_contribution_params(sb.sponsor_contribution)
            sb_params[:pricing_determinations] = pricing_determinations_params(sb)
            sb_params[:reference_product] = sb.reference_product.serializable_hash.deep_symbolize_keys
            sbs_array << sb_params
          end
        end

        def sponsor_contribution_params(current_sc)
          sb_params = current_sc.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :contribution_levels)
          sb_params[:contribution_levels] = contribution_levels_params(current_sc)
          sb_params
        end

        def contribution_levels_params(current_sc)
          current_sc.contribution_levels.inject([]) do |cls_array, cl|
            cls_array << cl.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
          end
        end

        def pricing_determinations_params(current_sb)
          current_sb.pricing_determinations.inject([]) do |pds_array, pd|
            pd_params = pd.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :pricing_determination_tiers)
            pd_params[:pricing_determination_tiers] = pricing_determination_tiers_params(pd)
            pds_array << pd_params
          end
        end

        def pricing_determination_tiers_params(current_pd)
          current_pd.pricing_determination_tiers.inject([]) do |pdts_array, pdt|
            pdts_array << pdt.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
          end
        end

        def build_benefit_application(ba_params)
          Build.new.call(ba_params)
        end

        def clone_benefit_application(ba_entity, values)
          new_ba = values[:benefit_application].benefit_sponsorship.benefit_applications.new(ba_entity.to_h)
          Success(new_ba)
        end
      end
    end
  end
end
