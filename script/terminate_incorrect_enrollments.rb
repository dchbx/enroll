# Takes enrollments that are terminated in Glue and terminates them in Enroll.
filename = "8905_policies_to_terminate.csv"

CSV.foreach(filename, headers: true) do |csv_row|
  hbx_enrollment = HbxEnrollment.by_hbx_id(csv_row["Enrollment Group ID"]).first
  end_date = Date.strptime(csv_row["Benefit End Date"],'%m/%d/%Y')
  if hbx_enrollment.benefit_group.plan_year.end_on != end_date
    hbx_enrollment.update_attribute(:terminated_on, end_date)
    hbx_enrollment.terminate_coverage! if hbx_enrollment.may_terminate_coverage?
  elsif hbx_enrollment.start_on == end_date
    hbx_enrollment.update_attribute(:terminated_on, end_date)
    hbx_enrollment.cancel_coverage! if hbx_enrollment.may_terminate_coverage?
  elsif hbx_enrollment.benefit_group.plan_year.end_on == end_date
    hbx_enrollment.expire_coverage! if hbx_enrollment.may_terminate_coverage?
  end
end
