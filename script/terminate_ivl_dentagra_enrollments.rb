carrier_profile = CarrierProfile.all.detect{|x| x.legal_name == "Dentegra"}
plan_ids = Plan.where(:carrier_profile_id => carrier_profile.id, :active_year => 2016, :market => 'individual').map(&:id)

families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:plan_id.in => plan_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES}})

families.each do |family|
  enrollments = family.active_household.hbx_enrollments.where({:plan_id.in => plan_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES})
  enrollments.each do |enrollment|
    enrollment.update!(terminated_on: Date.new(2016,12,31))
    enrollment.schedule_coverage_termination!

    puts "#{family.primary_applicant.person.full_name} terminated #{enrollment.hbx_id}----with #{enrollment.terminated_on} date"
  end
end