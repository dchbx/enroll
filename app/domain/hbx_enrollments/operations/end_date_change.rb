# frozen_string_literal: true

require 'dry/monads'

module HbxEnrollments
  module Operations
    class EndDateChange
      include Config::AcaModelConcern
      include Dry::Monads[:result, :do]

      def call(params)
        param_values                                      = yield validate(params)
        policy                                            = yield find_policy(param_values)
        _is_term_policy, _valid_term_date, _updatable     = yield [is_term_policy(policy),
                                                                   end_date_updatable(policy, param_values[:new_term_date]),
                                                                   new_term_date_valid(policy, param_values[:new_term_date])]
        fetch_end_date_values                             = yield fetch_end_date_params(policy, param_values[:new_term_date])
        end_date_values                                   = yield validate_end_date_params(fetch_end_date_values)
        enrollment_entity                                 = yield entity(end_date_values)
        enrollment                                        = yield persist(enrollment_entity, param_values[:edi_required])

        Success(enrollment)
      end

      private

      def validate(params)
        values = HbxEnrollments::Validators::EndDateChangeContract.new.call(params)
        if values.success?
          Success(values)
        else
          Failure(values.errors.to_h)
        end
      end

      def validate_end_date_params(params)
        contract = if params['kind'] == "employer_sponsored"
                     HbxEnrollments::Validators::ShopTermContract
                   else
                     HbxEnrollments::Validators::IvlTermContract
                   end
        values = contract.new.call(params)
        if values.success?
          Success(values)
        else
          Failure(values.errors.to_h)
        end
      end

      def find_policy(params)
        hbx_enrollment = HbxEnrollments::Operations::FindModel.new.call(params)
        if hbx_enrollment.success?
          Success(hbx_enrollment).flatten
        else
          Failure("policy not found")
        end
      end

      def is_term_policy(policy)
        result = (policy.coverage_terminated? || policy.coverage_termination_pending?)
        if result
          Success(result)
        else
          Failure("not a term policy")
        end
      end

      def new_term_date_valid(policy, new_term_date)
        coverage_last_date = policy.is_shop? ? policy.sponsored_benefit_package.end_on : policy.effective_on.end_of_year
        result = (new_term_date <= [TimeKeeper.date_of_record, coverage_last_date.to_date].min)
        if result
          Success(result)
        else
          Failure("not a valid new term date")
        end
      end

      def end_date_updatable(policy,new_term_date)
        result = (policy.effective_on.year > (TimeKeeper.date_of_record.year - aca_past_enrollment_eligible_to_reterm_year)) && policy.coverage_period_date_range.include?(new_term_date)
        if result
          Success(result)
        else
          Failure("not a valid policy to change end date")
        end
      end

      def fetch_end_date_params(policy, new_term)
        new_end_date_params = policy.attributes.except(:_id, :hbx_id, :aasm_state, :created_at, :updated_at, :version, :updated_by_id, :workflow_state_transitions)
        new_end_date_params['effective_on'] = new_end_date_params["effective_on"].to_date
        new_end_date_params['submitted_at'] = new_end_date_params["submitted_at"].to_date
        new_end_date_params['termination_submitted_on'] = new_term
        new_end_date_params['terminated_on'] = new_term
        new_end_date_params['predecessor_enrollment_id'] = policy.id
        new_end_date_params['hbx_enrollment_members'].each do |mem|
          mem['eligibility_date'] =  mem['eligibility_date'].to_date
          mem['coverage_start_on'] =  mem['coverage_start_on'].to_date
          mem['coverage_end_on'] = new_term
        end

        Success(new_end_date_params)
      end

      def entity(end_date_values)
        model = if end_date_values['kind'] == "employer_sponsored"
                  ::HbxEnrollments::Entities::ShopEnrollment
                else
                  ::HbxEnrollments::Entities::IvlEnrollment
                end
        enrollment_entity = model.new(end_date_values.to_h)
        Success(enrollment_entity)
      end

      def persist(entity, edi)
        new_enrollment = HbxEnrollments::Operations::Persist.new.call(entity, edi).flatten
        Success(new_enrollment)
      end
    end
  end
end