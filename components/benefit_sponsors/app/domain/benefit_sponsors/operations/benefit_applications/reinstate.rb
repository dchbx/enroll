# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitApplications
      # This class reinstates a canceled/terminated/termination_pending
      # benefit_application where end result is a new benefit_application.
      # The effective_period of the newly created benefit_application depends
      # on the aasm_state of the input benefit_application. The aasm_state of the
      # newly created application will be active but there will be a transition
      # from draft to reinstated before the final state(active) to indicate that
      # this very application is reinstated.
      class Reinstate
        include Dry::Monads[:result, :do]

        # @param [ BenefitSponsors::BenefitApplications::BenefitApplication ] benefit_application
        # @return [ BenefitSponsors::BenefitApplications::BenefitApplication ] benefit_application
        def call(params)
          values              = yield validate(params)
          filtered_values     = yield filter(values)
          effective_period    = yield effective_period_range(filtered_values)
          new_ba              = yield new_benefit_application(filtered_values, effective_period)
          benefit_application = yield reinstate(new_ba)

          Success(benefit_application)
        end

        private

        def validate(params)
          return Failure('Missing Key.') unless params.key?(:benefit_application)
          return Failure('Not a valid Benefit Application object.') unless params[:benefit_application].is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)

          Success(params)
        end

        def filter(values)
          valid_states_for_reinstatement = [:terminated, :termination_pending, :canceled]
          return Failure("Given BenefitApplication is not in any of the #{valid_states_for_reinstatement} states.") unless valid_states_for_reinstatement.include?(values[:benefit_application].aasm_state)
          Success(values)
        end

        def effective_period_range(params)
          current_ba = params[:benefit_application]
          case current_ba.aasm_state
          when :terminated
            Success((current_ba.terminated_on + 1.day)..current_ba.effective_period.max)
          when :termination_pending
            Success((current_ba.terminated_on + 1.day)..current_ba.effective_period.max)
          when :canceled
            Success(current_ba.effective_period)
          else
            Failure("Cannot determine effective_period because of the aasm_state: #{current_ba.aasm_state}")
          end
        end

        def new_benefit_application(params, effective_period)
          current_ba = params[:benefit_application]
          new_ba = init_benefit_application(current_ba, current_ba.benefit_sponsorship, effective_period)

          current_ba.benefit_packages.each do |bp|
            new_bp = init_benefit_package(bp, new_ba)

            bp.sponsored_benefits.each do |sb|
              new_sb = init_sponsored_benefit(sb, new_bp)

              sc = sb.sponsor_contribution
              new_sc = init_sponsor_contribution(sc, new_sb)

              sc.contribution_levels.each do |cl|
                init_contribution_level(cl, new_sc)
              end

              sb.pricing_determinations.each do |pd|
                init_pricing_determination(pd, new_sb)
              end
            end
          end

          if new_ba.valid?
            new_ba.save!
            Success(new_ba)
          else
            Failure(new_ba.errors.to_h)
          end
        end

        def init_benefit_application(current_ba, benefit_sponsorship, effective_period)
          ba_params = current_ba.attributes.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :terminated_on, :termination_reason, :termination_kind, :benefit_packages, :workflow_state_transitions)
          ba_params.merge!({aasm_state: :draft, effective_period: effective_period, reinstated_id: current_ba.id})
          new_ba = benefit_sponsorship.benefit_applications.new
          new_ba.assign_attributes(ba_params)
          new_ba
        end

        def init_benefit_package(current_bp, new_ba)
          bp_params = current_bp.attributes.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :sponsored_benefits)
          new_bp = new_ba.benefit_packages.new
          new_bp.assign_attributes(bp_params)
          new_bp
        end

        def init_sponsored_benefit(current_sb, new_bp)
          sb_params = current_sb.attributes.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :sponsor_contribution, :pricing_determinations)
          new_sb = new_bp.sponsored_benefits.new
          new_sb.assign_attributes(sb_params)
          new_sb.reference_product = current_sb.reference_product
          new_sb
        end

        def init_sponsor_contribution(current_sc, new_sb)
          sc_params = current_sc.attributes.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :contribution_levels)
          new_sc = new_sb.build_sponsor_contribution
          new_sc.assign_attributes(sc_params)
          new_sc
        end

        def init_contribution_level(current_cl, new_sc)
          cl_params = current_cl.attributes.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
          new_cl = new_sc.contribution_levels.new
          new_cl.assign_attributes(cl_params)
        end

        def init_pricing_determination(current_pd, new_sb)
          pd_params = current_pd.attributes.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :pricing_determination_tiers)
          new_pd = new_sb.pricing_determinations.new
          new_pd.assign_attributes(pd_params)

          current_pd.pricing_determination_tiers.each do |pdt|
            init_pricing_determination_tier(pdt, new_pd)
          end
        end

        def init_pricing_determination_tier(current_pdt, new_pd)
          pdt_params = current_pdt.attributes.deep_symbolize_keys.except(:_id, :created_at, :updated_at)
          new_pdt = new_pd.pricing_determination_tiers.new
          new_pdt.assign_attributes(pdt_params)
        end

        def reinstate(new_ba)
          return Failure('Cannot transition to state reinstated on event reinstate.') unless new_ba.may_reinstate?

          new_ba.reinstate!
          return Failure('Cannot transition to state active on event activate_enrollment.') unless new_ba.may_activate_enrollment?

          new_ba.activate_enrollment!
          Success(new_ba)
        end
      end
    end
  end
end
