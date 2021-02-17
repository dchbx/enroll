# frozen_string_literal: true

module Operations
  module BenefitGroupAssignments
    # This class reinstates a benefit_group_assignment where end result
    # is a new benefit_group_assignment. The start_on of the newly
    # created benefit_group_assignment depends on the input benefit package.
    class Reinstate
      include Dry::Monads[:result, :do]

      # @param [ BenefitGroupAssignment ] benefit_group_assignment
      # @param [ Hash ] options include new benefit package which will
      # be assigned to new benefit group assignment
      # @return [ BenefitGroupAssignment ] benefit_group_assignment
      def call(params)
        values           = yield validate(params)
        cloned_bga       = yield cloned_benefit_group_assignment(values)
        bga              = yield persist_benefit_group_assignment(cloned_bga)

        Success(bga)
      end

      private

      def validate(params)
        benefit_group_assignment = params[:benefit_group_assignment]
        return Failure('Missing Key.') unless benefit_group_assignment.present?
        return Failure('Not a valid BenefitGroupAssignment object.') unless benefit_group_assignment.is_a?(BenefitGroupAssignment)
        return Failure('End on must be present for the given benefit group assignment.') if benefit_group_assignment.end_on.blank?
        return Failure('Benefit Package must be present for this benefit group assignment.') if benefit_group_assignment.benefit_package_id.blank?
        return Failure('Invalid Benefit Group. End on cannot occur before the start on.') if benefit_group_assignment.end_on < benefit_group_assignment.start_on
        return Failure("Unable to fetch new benefit package") if fetch_benefit_package(benefit_group_assignment, params[:options]).blank?
        return Failure('Overlapping benefit group assignments present') if overlapping_bga_exists?
        return Failure('New benefit group assignment cannot fall outside the plan year') unless is_eligible_to_reinstate_bga?

        Success(params)
      end

      def cloned_benefit_group_assignment(values)
        Clone.new.call({benefit_group_assignment: values[:benefit_group_assignment], options: additional_params})
      end

      def persist_benefit_group_assignment(bga)
        bga.save! ? Success(bga) : Failure('Unable to persist benefit group assignment')
      end

      def overlapping_bga_exists?
        @census_employee.benefit_group_assignments.by_benefit_package(@new_benefit_package).any? {|bga| bga.is_active?(@start_on)}
      end

      def is_eligible_to_reinstate_bga?
        @new_benefit_package.effective_period.cover?(@start_on)
      end

      def additional_params
        {start_on: @start_on, benefit_package_id: @new_benefit_package.id, activated_at: TimeKeeper.datetime_of_record}
      end

      def fetch_benefit_package(bga,options)
        @old_bga = bga
        @census_employee = @old_bga.census_employee
        @start_on = @old_bga.canceled? ? @old_bga.start_on : @old_bga.end_on.next_day
        @new_benefit_package = if options[:benefit_package].present?
                                 options[:benefit_package]
                               else
                                 title = @old_bga.benefit_package.title
                                 benefit_sponsorship = @old_bga.benefit_package.benefit_sponsorship
                                 ba = benefit_sponsorship.benefit_applications.detect { |application| application.effective_period.cover?(@start_on) }
                                 ba.benefit_packages.detect{|bp| bp.title == title} if ba.present?
                               end
      end
    end
  end
end
