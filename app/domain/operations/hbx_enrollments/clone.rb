# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # This class clones a hbx_enrollment where end
    # result is a new hbx_enrollment. The aasm_state
    # of the newly created application will be shopping irrespective
    # of the aasm_state of the input hbx_enrollment.
    # Also, the result hbx_enrollment is a non-persisted object.
    class Clone
      include Dry::Monads[:result, :do]

      # @param [ HbxEnrollment ] hbx_enrollment
      # @param [ Date ] effective_on for new hbx_enrollment
      # @param [ Hash ] options additional attributes for new hbx_enrollment
      # @return [ HbxEnrollment ] hbx_enrollment
      def call(params)
        values         = yield validate(params)
        enr_params     = yield construct_params(values)
        enr_entity     = yield build_hbx_enrollment(enr_params)
        hbx_enrollment = yield clone_hbx_enrollment(enr_entity)

        Success(hbx_enrollment)
      end

      private

      def validate(params)
        return Failure('Missing Keys.') unless params.key?(:hbx_enrollment) && params.key?(:effective_on) && params.key?(:options)
        return Failure('Not a valid HbxEnrollment object.') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure("Invalid options's value. Should be a Hash.") unless params[:options].is_a?(Hash)

        Success(params)
      end

      def construct_params(values)
        @current_enrollment = values[:hbx_enrollment]
        enr_params = @current_enrollment.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :elected_aptc_pct, :applied_aptc_amount, :terminated_on, :terminate_reason, :hbx_enrollment_members, :workflow_state_transitions)
        enr_params.merge!({aasm_state: 'shopping', effective_on: values[:effective_on]})
        enr_params.merge!(values[:options])
        enr_params[:hbx_enrollment_members] = hbx_enrollment_members_params
        Success(enr_params)
      end

      def hbx_enrollment_members_params
        @current_enrollment.hbx_enrollment_members.inject([]) do |members_array, member|
          member_params = member.serializable_hash.deep_symbolize_keys.except(:_id, :created_at, :updated_at, :coverage_end_on)
          members_array << member_params
        end
      end

      def build_hbx_enrollment(enr_params)
        Build.new.call(enr_params)
      end

      def clone_hbx_enrollment(enr_entity)
        enr_params = enr_entity.to_h
        enrollment = ::HbxEnrollment.new
        enrollment.assign_attributes(enr_params.except(:hbx_enrollment_members, :workflow_state_transitions))
        enrollment.family = @current_enrollment.family
        enrollment.household = @current_enrollment.household

        enr_params[:hbx_enrollment_members].each do |member_params|
          init_hbx_enrollment_member(member_params, enrollment)
        end
        Success(enrollment)
      end

      def init_hbx_enrollment_member(member_params, enrollment)
        new_enrollment_member = enrollment.hbx_enrollment_members.new
        new_enrollment_member.assign_attributes(member_params)
        new_enrollment_member
      end
    end
  end
end
