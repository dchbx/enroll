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
          effective_period    = yield effective_period_range(values)
          new_ba              = yield new_benefit_application(values, effective_period)
          benefit_application = yield reinstate(new_ba)

          Success(benefit_application)
        end

        private

        def validate(params)
          return Failure('Missing Key.') unless params.key?(:benefit_application)
          return Failure('Not a valid Benefit Application object.') unless params[:benefit_application].is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)
          valid_states_for_reinstatement = [:terminated, :termination_pending, :canceled]
          return Failure("Given BenefitApplication is not in any of the #{valid_states_for_reinstatement} states.") unless valid_states_for_reinstatement.include?(params[:benefit_application].aasm_state)

          Success(params)
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
          clone_result = Clone.new.call({benefit_application: params[:benefit_application], effective_period: effective_period})
          return clone_result if clone_result.failure?
          new_ba = clone_result.success
          new_ba.assign_attributes({reinstated_id: params[:benefit_application].id})
          new_ba.save!
          Success(new_ba)
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
