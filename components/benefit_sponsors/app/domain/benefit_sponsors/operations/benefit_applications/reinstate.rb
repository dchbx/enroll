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
          new_ba              = yield new_benefit_application(values)
          benefit_application = yield reinstate(new_ba)

          Success(benefit_application)
        end

        private

        def validate(params)
          return Failure('Missing Key.') unless params.key?(:benefit_application)
          return Failure('Not a valid Benefit Application object.') unless params[:benefit_application].is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)
          valid_states_for_reinstatement = [:terminated, :termination_pending, :canceled]
          return Failure("Given BenefitApplication is not in any of the #{valid_states_for_reinstatement} states.") unless valid_states_for_reinstatement.include?(params[:benefit_application].aasm_state)
          return Failure('Overlapping BenefitApplication exists for this Employer.') if overlapping_ba_exists?(params)

          Success(params)
        end

        def overlapping_ba_exists?(params)
          @effective_period = effective_period_range(params)
          # benefit_sponsorship = params[:benefit_application].benefit_sponsorship
          # benefit_sponsorship.benefit_applications.non_canceled.any?{|ba| ba.effective_period.cover?(@effective_period.min)}

          # TODO: Refactor this code while working on ticket 90968.
          false
        end

        def effective_period_range(params)
          current_ba = params[:benefit_application]
          case current_ba.aasm_state
          when :terminated
            (current_ba.terminated_on + 1.day)..current_ba.effective_period.max
          when :termination_pending
            (current_ba.terminated_on + 1.day)..current_ba.effective_period.max
          when :canceled
            current_ba.effective_period
          end
        end

        def new_benefit_application(params)
          clone_result = Clone.new.call({benefit_application: params[:benefit_application], effective_period: @effective_period})
          return clone_result if clone_result.failure?
          new_ba = clone_result.success

          bsc = new_benefit_sponsor_catalog(params[:benefit_application])
          new_ba.assign_attributes({reinstated_id: params[:benefit_application].id, benefit_sponsor_catalog_id: bsc.id})
          new_ba.save!
          Success(new_ba)
        end

        def new_benefit_sponsor_catalog(current_ba)
          bsc = current_ba.benefit_sponsorship.benefit_sponsor_catalog_for(current_ba.effective_period.min)
          bsc.save!
          bsc
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
