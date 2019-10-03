module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationEnrollmentsQuery

      attr_reader :benefit_application, :sponsored_benefit

      def initialize(benefit_application, sponsored_benefit)
        @benefit_application = benefit_application
        @sponsored_benefit = sponsored_benefit
      end

      def call(klass_name, date)
        end_date = (benefit_application.effective_period.min > date.end_of_month) ? benefit_application.effective_period.min : date.end_of_month
        klass_name.collection.aggregate([
          {"$match" => {"hbx_enrollment_members" => { "$exists" => true }}},
          {"$project" =>  {
            "sponsored_benefit_id" => 1,
            "aasm_state" => 1,
            "effective_on" => 1,
            "terminated_on" => 1,
            "employee_role_id" => 1,
            "submitted_at" => 1
          }},
          {"$match" => {
            "sponsored_benefit_id" => @sponsored_benefit.id,
            "aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)},
            "effective_on" =>  {"$lte" => end_date, "$gte" => benefit_application.effective_period.min},
            "$or" => [
             {"terminated_on" => {"$eq" => nil} },
             {"terminated_on" => {"$gte" => date.end_of_month}}
            ]
          }},
          {"$sort" => {
            "submitted_at" => 1
          }},
          {"$group" => {
            "_id" => {
              "bga_id" => "$sponsored_benefit_id",
              "employee_role_id" => "$employee_role_id"
            },
            "hbx_enrollment_id" => {"$last" => "$_id"},
            "hbx_enrollments" => {"$last" => "$$ROOT"}
          }}
        ])
      end
    end
  end
end
