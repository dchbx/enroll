module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationEnrollmentsQuery

      attr_reader :benefit_application, :sponsored_benefit

      def initialize(benefit_application, sponsored_benefit)
        @benefit_application = benefit_application
        @sponsored_benefit = sponsored_benefit
      end

      def call(klass_name, date)
        klass_name.collection.aggregate([
          {"$match" => { "households.hbx_enrollments" => {
            "$elemMatch" => {
            "sponsored_benefit_id" => @sponsored_benefit.id,
            "aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)},
            "effective_on" =>  {"$lte" => date.end_of_month, "$gte" => benefit_application.effective_period.min}
          }}}},
          {"$unwind" => "$households"},
          {"$unwind" => "$households.hbx_enrollments"},
          {"$match" => {
            "households.hbx_enrollments.sponsored_benefit_id" => @sponsored_benefit.id,
            "households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES)},
            "households.hbx_enrollments.effective_on" =>  {"$lte" => date.end_of_month, "$gte" => benefit_application.effective_period.min},
            "$or" => [
             {"households.hbx_enrollments.terminated_on" => {"$eq" => nil} },
             {"households.hbx_enrollments.terminated_on" => {"$gte" => date.end_of_month}}
            ]
          }},
          {"$sort" => {
            "households.hbx_enrollments.submitted_at" => 1
          }},
          {"$group" => {
            "_id" => {
              "bga_id" => "$households.hbx_enrollments.sponsored_benefit_id",
              "employee_role_id" => "$households.hbx_enrollments.employee_role_id"
            },
            "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments._id"},
            "hbx_enrollments" => {"$last" => "$households.hbx_enrollments"}
          }}
        ])
      end
    end
  end
end
