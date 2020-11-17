# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitApplications
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
          return Failure('Missing Key.') unless params.key?(:benefit_application) || params.key?(:effective_period)
          return Failure('Not a valid Benefit Application object.') unless params[:benefit_application].is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)
          return Failure('Invalid effective_period') if params[:effective_period].min > params[:effective_period].max

          Success(params)
        end

        def construct_params(values)
          current_ba = values[:benefit_application]
          ba_params = current_ba.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :benefit_packages, :workflow_state_transitions)
          ba_params.merge!({aasm_state: :draft,
                            effective_period: values[:effective_period],
                            reinstated_id: current_ba.id,
                            termination_on: nil,
                            termination_kind: '',
                            termination_reason: ''})
          ba_params.merge!({expiration_date: ba_params[:expiration_date].to_datetime}) if ba_params[:expiration_date].present?
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
            sb_params[:_type] = sb._type
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
          ba_params = ba_entity.to_h
          new_ba = values[:benefit_application].benefit_sponsorship.benefit_applications.new
          new_ba.assign_attributes(ba_params.except(:benefit_packages, :workflow_state_transitions))

          ba_params[:benefit_packages].each do |bp_params|
            new_bp = init_benefit_package(bp_params, new_ba)

            bp_params[:sponsored_benefits].each do |sb_params|
              new_sb = init_sponsored_benefit(sb_params, new_bp)

              sc_params = sb_params[:sponsor_contribution]
              new_sc = init_sponsor_contribution(sc_params, new_sb)

              sc_params[:contribution_levels].each do |cl_params|
                init_contribution_level(cl_params, new_sc)
              end

              sb_params[:pricing_determinations].each do |pd_params|
                init_pricing_determination(pd_params, new_sb)
              end
            end
          end
          Success(new_ba)
        end

        def init_benefit_package(bp_params, new_ba)
          new_bp = new_ba.benefit_packages.new
          new_bp.assign_attributes(bp_params.except(:sponsored_benefits))
          new_bp
        end

        def init_sponsored_benefit(sb_params, new_bp)
          new_sb = new_bp.sponsored_benefits.new
          new_sb.assign_attributes(sb_params.except(:sponsor_contribution, :pricing_determinations, :reference_product))
          new_sb.reference_product = ::BenefitMarkets::Products::Product.find(sb_params[:reference_product][:_id])
          new_sb
        end

        def init_sponsor_contribution(sc_params, new_sb)
          new_sc = new_sb.build_sponsor_contribution
          new_sc.assign_attributes(sc_params.except(:contribution_levels))
          new_sc
        end

        def init_contribution_level(cl_params, new_sc)
          new_cl = new_sc.contribution_levels.new
          new_cl.assign_attributes(cl_params)
        end

        def init_pricing_determination(pd_params, new_sb)
          new_pd = new_sb.pricing_determinations.new
          new_pd.assign_attributes(pd_params.except(:pricing_determination_tiers))

          pd_params[:pricing_determination_tiers].each do |pdt_params|
            init_pricing_determination_tier(pdt_params, new_pd)
          end
        end

        def init_pricing_determination_tier(pdt_params, new_pd)
          new_pdt = new_pd.pricing_determination_tiers.new
          new_pdt.assign_attributes(pdt_params)
        end
      end
    end
  end
end
