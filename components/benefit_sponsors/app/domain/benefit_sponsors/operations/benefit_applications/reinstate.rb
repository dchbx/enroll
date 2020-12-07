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
          values               = yield validate(params)
          cloned_ba            = yield clone_benefit_application(values)
          cloned_bsc           = yield clone_benefit_sponsor_catalog(values)
          new_ba               = yield new_benefit_application(values, cloned_ba, cloned_bsc)
          benefit_application  = yield reinstate(new_ba)
          _benefit_sponsorship = yield reinstate_after_effects(benefit_application)

          Success(benefit_application)
        end

        private

        def validate(params)
          return Failure('Missing Key.') unless params.key?(:benefit_application)
          @current_ba = params[:benefit_application]
          return Failure('Not a valid Benefit Application object.') unless @current_ba.is_a?(BenefitSponsors::BenefitApplications::BenefitApplication)
          valid_states_for_reinstatement = [:terminated, :termination_pending, :canceled]
          return Failure("Given BenefitApplication is not in any of the #{valid_states_for_reinstatement} states.") unless valid_states_for_reinstatement.include?(@current_ba.aasm_state)
          return Failure("Given BenefitApplication's effective starting date is not in the past 12 months.") unless initial_ba_within_valid_timeframe?
          return Failure('Overlapping BenefitApplication exists for this Employer.') if overlapping_ba_exists?

          Success(params)
        end

        def initial_ba_within_valid_timeframe?
          start_on = @current_ba.benefit_sponsor_catalog.effective_period.min
          start_of_month = TimeKeeper.date_of_record.beginning_of_month
          timeframe_months = EnrollRegistry[:reinstate_timeframe].setting(:timeframe_months).item
          ((start_of_month.next_month - timeframe_months.months)..start_of_month.end_of_month).cover?(start_on)
        end

        def parent_ba_by_reinstate_id(benefit_application)
          reinstated_id = benefit_application.reinstated_id
          reinstated_id.nil? ? benefit_application : parent_ba_by_reinstate_id(benefit_application.parent_reinstate_application)
        end

        def overlapping_ba_exists?
          @effective_period = effective_period_range
          valid_bas = @current_ba.benefit_sponsorship.benefit_applications.non_canceled.where(:id.ne => @current_ba.id)
          valid_bas.any?{|ba| ba.effective_period.cover?(@effective_period.min) || ba.effective_period.min >= @effective_period.min}
        end

        def effective_period_range
          @parent_application = parent_ba_by_reinstate_id(@current_ba)
          case @current_ba.aasm_state
          when :terminated, :termination_pending
            (@current_ba.effective_period.max.next_day)..(@parent_application.effective_period.min.next_year.prev_day)
          when :canceled
            @current_ba.effective_period
          end
        end

        def clone_benefit_application(values)
          Clone.new.call({benefit_application: values[:benefit_application], effective_period: @effective_period})
        end

        def clone_benefit_sponsor_catalog(values)
          ::BenefitMarkets::Operations::BenefitSponsorCatalogs::Clone.new.call(benefit_sponsor_catalog: values[:benefit_application].benefit_sponsor_catalog)
        end

        def new_benefit_application(values, cloned_ba, cloned_bsc)
          cloned_bsc.benefit_application = cloned_ba
          cloned_bsc.save!
          cloned_ba.assign_attributes({reinstated_id: values[:benefit_application].id, benefit_sponsor_catalog_id: cloned_bsc.id})
          cloned_ba.save!
          Success(cloned_ba)
        end

        def reinstate(new_ba)
          return Failure('Cannot transition to state reinstated on event reinstate.') unless new_ba.may_reinstate?

          new_ba.reinstate!
          return Failure('Cannot transition to state active on event activate_enrollment.') unless new_ba.may_activate_enrollment?

          new_ba.activate_enrollment!
          Success(new_ba)
        end

        def reinstate_after_effects(reinstated_ba)
          months_prior_to_effective = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months.abs
          renewal_ba_generation_date = reinstated_ba.end_on.next_day.to_date - months_prior_to_effective.months
          return Success(reinstated_ba.benefit_sponsorship) unless TimeKeeper.date_of_record >= renewal_ba_generation_date

          ba_enrollment_service = ::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(reinstated_ba)
          ba_enrollment_service.renew_application
          Success(reinstated_ba.benefit_sponsorship)
        end
      end
    end
  end
end
