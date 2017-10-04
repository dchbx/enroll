require 'csv'

namespace :reports do

  # Following task will generate new hire enrollments report which are gated from automatic transmission.
  # rake reports:gapped_new_hire_enrollments["8/1/2017","9/25/2017"]

  desc "New hire enrollments report"
  task :gapped_new_hire_enrollments, [:start_date, :end_date] => :environment do |task, args|
    start_date = Date.strptime(args['start_date'].to_s, "%m/%d/%Y")
    end_date = Date.strptime(args['end_date'].to_s, "%m/%d/%Y")

    start_time = TimeKeeper.start_of_exchange_day_from_utc(start_date)
    end_time = TimeKeeper.end_of_exchange_day_from_utc(end_date)

    purchase_ids = Family.collection.aggregate([
      {"$match" => {
        "households.hbx_enrollments.workflow_state_transitions" => {
          "$elemMatch" => {
            "to_state" => "coverage_selected",
            "transition_at" => {
             "$gte" => start_time,
             "$lt" => end_time
           }
         }
       }
       }},
       {"$unwind" => "$households"},
       {"$unwind" => "$households.hbx_enrollments"},
       {"$match" => {
        "households.hbx_enrollments.workflow_state_transitions" => {
          "$elemMatch" => {
            "to_state" => "coverage_selected",
            "transition_at" => {
             "$gte" => start_time,
             "$lt" => end_time
           }
         }
         },
         "households.hbx_enrollments.kind" => {"$in" => ["employer_sponsored"]}
         }},
         {"$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}}
         ]).map { |rec| rec["_id"] }

    def is_valid_plan_year?(plan_year)
      %w(enrolled renewing_enrolled canceled expired renewing_canceled active terminated termination_pending).include?(plan_year.aasm_state)
    end

    def can_publish_enrollment?(enrollment, transition_at)
      plan_year = enrollment.benefit_group.plan_year
      if is_valid_plan_year?(plan_year)
        if enrollment.new_hire_enrollment_for_shop? && (enrollment.effective_on <= (transition_at - 2.months))
          return true
        end
      end
      false
    end

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    @logger = Logger.new("#{Rails.root}/log/gapped_new_hire_enrollments_report.log")

    CSV.open("#{Rails.root}/hbx_report/gapped_new_hire_enrollments_#{start_date.strftime('%m_%d_%Y')}_#{end_date.strftime('%m_%d_%Y')}.csv", "w", force_quotes: true) do |csv|

      csv << [
        "Employer Hbx ID",
        "Employer Legal Name",
        "Plan Year Begin Date",
        "Plan Year Status",
        "Enrollment Group ID",
        "Employee HBX ID",
        "Employee Hired On",
        "Market Kind",
        "Enrollment Kind",
        "Coverage Kind",
        "Enrollment Status",
        "Purchase Date",
        "Coverage Start Date",
        "Coverage End Date",
        "Termination Reason",
        "HIOS ID",
        "Plan Name",
        "Employee Cost",
        "Employer premium Contribution",
        "Premium Total"
      ]

      puts purchase_ids.inspect

      purchase_families = Family.where("households.hbx_enrollments.hbx_id" => {"$in" => purchase_ids})

      purchase_families.each do |fam|
        purchases = fam.households.flat_map(&:hbx_enrollments).select { |en| purchase_ids.include?(en.hbx_id) }
        purchases.each do |enrollment|
          purchased_at = enrollment.workflow_state_transitions.where({
            "to_state" => 'coverage_selected',
            "transition_at" => {
              "$gte" => start_time,
              "$lt" => end_time
            }
            }).first.transition_at

          if can_publish_enrollment?(enrollment, purchased_at)

            plan_year = enrollment.benefit_group.plan_year
            employer = plan_year.employer_profile

            costs = [nil, nil, nil]
            if !enrollment.coverage_canceled?
              costs = [
                enrollment.total_employee_cost,
                enrollment.total_employer_contribution,
                enrollment.total_premium
              ]
            end

            coverage_end = plan_year.end_on
            if enrollment.coverage_terminated? || enrollment.coverage_termination_pending?
              coverage_end = enrollment.terminated_on
            end

            csv << [
              employer.hbx_id,
              employer.legal_name,
              plan_year.start_on.strftime('%m/%d/%Y'),
              plan_year.aasm_state.humanize,
              enrollment.hbx_id,
              enrollment.family.primary_applicant.person.hbx_id,
              enrollment.benefit_group_assignment.census_employee.hired_on.strftime('%m/%d/%Y'),
              enrollment.kind,
              enrollment.enrollment_kind.humanize,
              enrollment.coverage_kind,
              enrollment.aasm_state.humanize,
              purchased_at.strftime('%m/%d/%Y'),
              enrollment.effective_on.strftime('%m/%d/%Y'),
              coverage_end.present? ? coverage_end.strftime('%m/%d/%Y') : nil,
              enrollment.terminate_reason,
              enrollment.plan.hios_id,
              enrollment.plan.name
              ] + costs
          end
        end
      end
    end
  end
end