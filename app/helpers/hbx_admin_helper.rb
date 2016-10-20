module HbxAdminHelper

  def full_name_of_person(person_id)
    Person.find(person_id).full_name
  end

  def ehb_percent_for_enrollment(hbx_id)
  	ehb = HbxEnrollment.find(hbx_id).plan.ehb
  	enb_percent = (ehb*100).round(2)
  end
  
  def max_aptc_that_can_be_applied_for_this_enrollment(hbx_id, max_aptc_for_household)
  	#1 Get all members in the enrollment
  	#2 Get APTC ratio for each of these members
  	#3 Max APTC for Enrollment => Sum all (ratio * max_aptc) for each members
  	max_aptc_for_enrollment = 0
  	hbx = HbxEnrollment.find(hbx_id)
  	hbx_enrollment_members = hbx.hbx_enrollment_members
  	aptc_ratio_by_member = hbx.family.active_household.latest_active_tax_household.aptc_ratio_by_member
  	hbx_enrollment_members.each do |hem|
    	max_aptc_for_enrollment += (aptc_ratio_by_member[hem.applicant_id.to_s].to_f * max_aptc_for_household.to_f)
  	end
  	if max_aptc_for_enrollment > max_aptc_for_household.to_f
        max_aptc_for_household.to_f
  	else
      max_aptc_for_enrollment.to_f
  	end
  end

  def aptc_csr_data_type(month)
    month_num = Date::ABBR_MONTHNAMES.index(month.to_s.capitalize || month.to_s)
    this_month_date = Date.parse("#{TimeKeeper.date_of_record.year}-#{month_num}-01")
    todays_date = TimeKeeper.date_of_record
    if this_month_date < todays_date
      td_style = 'past-aptc-csr-data'
    else
      td_style="current-aptc-csr-data"
    end
  end

  def find_applied_aptc_percent(aptc_applied, max_aptc)
    return 0 if max_aptc == 0.to_f
    ((aptc_applied/max_aptc)*100).round
  end

  def inactive_and_without_aptc_enrollments(family, year)
    family.active_household.hbx_enrollments.canceled_and_terminated.with_plan.with_aptc.by_year(TimeKeeper.date_of_record.year) +
    family.active_household.hbx_enrollments.with_plan.without_aptc.by_year(TimeKeeper.date_of_record.year)
  end

end
