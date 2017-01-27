require 'csv'

filename = "redmine_6922_7580.csv"

def select_benefit_package(title, benefit_coverage_period)
	benefit_coverage_period.benefit_packages.each do |benefit_package|
		if benefit_package.title == title
			return benefit_package
		end
	end
end

def select_benefit_group_assignment(correct_benefit_group,benefit_group_assignments)
	correct_benefit_group_assignment = nil
	benefit_group_assignments.each do |benefit_group_assignment|
		if benefit_group_assignment.benefit_group_id == correct_benefit_group._id
			correct_benefit_group_assignment = benefit_group_assignment
		end
	end
	return correct_benefit_group_assignment
end

def get_all_benefit_groups(organization)
	all_benefit_groups = []
	organization.employer_profile.plan_years.each do |plan_year|
		plan_year.benefit_groups.each do |benefit_group|
			all_benefit_groups.push(benefit_group)
		end
	end
	return all_benefit_groups
end

def select_benefit_group_assignment(correct_benefit_group, census_employee)

	if census_employee.active_benefit_group_assignment.present? && census_employee.active_benefit_group_assignment.benefit_group == correct_benefit_group
		return census_employee.active_benefit_group_assignment
	end

  if match = census_employee.benefit_group_assignments.detect{|assignment| assignment.benefit_group == correct_benefit_group}
  	match.make_active
  	return match
  end

	return nil
end

def format_date(date)
	date = Date.strptime(date,'%m/%d/%Y')
end

def find_census_employee(subscriber_params)
	census_employee = CensusEmployee.where(encrypted_ssn: CensusMember.encrypt_ssn(subscriber_params["ssn"])).first
	if census_employee == nil
		census_employee = CensusEmployee.where(first_name: subscriber_params["first_name"],
											   middle_name: subscriber_params["middle_name"],
											   last_name: subscriber_params["last_name"],
											   dob: subscriber_params["dob"]).first
	end
	return census_employee
end

def create_person_details(subscriber_params)
	person_details = Forms::EmploymentRelationship.new
	person_details.name_pfx = subscriber_params["name_pfx"]
	person_details.first_name = subscriber_params["first_name"]
	person_details.middle_name = subscriber_params["middle_name"]
	person_details.last_name = subscriber_params["last_name"]
	person_details.name_sfx = subscriber_params["name_sfx"]
	person_details.gender = subscriber_params["gender"]
	return person_details
end

def find_dependent(ssn,dob,first_name,middle_name,last_name)
	person = Person.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).first
	if person == nil
		person = Person.where(first_name: first_name.strip, middle_name: middle_name.strip, last_name: last_name.strip, dob: format_date(dob))
	else
		return person
	end
	if person == nil
		return ArgumentError.new("dependent does not exist for provided person details")
	else
		return person
	end
end

def select_employee_role(employer_profile_id, employee_roles)
	correct_employee_role = employee_roles.detect{|employee_role| employee_role.employer_profile_id == employer_profile_id}
	return correct_employee_role
end

## Just for clarification
# EnrollmentFactory#construct_consumer_role
# EnrollmentFactory#initialize_dependent
# dependent_person.build_consumer_role(is_applicant: false)
# EnrollmentFactory#construct_employee_role
# EnrollmentFactory#initialize_dependent
# dependent_person.employee_roles.build(employer_profile: employer_profile, hired_on: hired_on)

CSV.foreach(filename, headers: :true) do |row|

	# begin
		data_row = row.to_hash
		subscriber = Person.where(hbx_id: data_row['HBX ID']).first
		subscriber_params = {"name_pfx" => data_row["Name Prefix"],
									 "first_name" => data_row["First Name"],
									 "middle_name" => data_row["Middle Name"],
									 "last_name" => data_row["Last Name"],
									 "name_sfx" => data_row["Name Suffix"],
									 "ssn" => data_row["SSN"].gsub("-",""),
									 "dob" => format_date(data_row["DOB"]),
									 "gender" => data_row["Gender"].downcase,
									 "no_ssn" => 0
									}

		person_details = create_person_details(subscriber_params)
		organization = Organization.where(fein: data_row["Employer FEIN"].gsub("-","")).first
		census_employee = find_census_employee(subscriber_params)
    census_dependents = []
		6.times do |i|
			if data_row["HBX ID (Dep #{i+1})"].present?
				census_dependents << CensusDependent.new({
					first_name: data_row["First Name (Dep #{i+1})"],
					middle_name: data_row["Middle Name (Dep #{i+1})"],
					last_name: data_row["Last Name (Dep #{i+1})"],
					dob: format_date(data_row["DOB (Dep #{i+1})"]),
					employee_relationship: data_row["Relationship (Dep #{i+1})"].strip == 'child' ? 'child_under_26' : data_row["Relationship (Dep #{i+1})"].strip,
					gender:  data_row["Gender (Dep #{i+1})"],
					ssn: data_row["SSN (Dep #{i+1})"].to_s.strip.gsub("-","")
					})
			end
		end


    puts "processing #{census_employee.full_name}"

		if census_employee.census_dependents.blank? && census_dependents.present?
			census_employee.census_dependents = census_dependents
			census_employee.save!
		end


				  benefit_begin_date = format_date(data_row["Benefit Begin Date"])
				  plan_year = organization.employer_profile.plan_years.published_plan_years_by_date(benefit_begin_date).first
				  plan_year = organization.employer_profile.plan_years.detect{|py| (py.start_on..py.end_on).cover?(benefit_begin_date)} if plan_year.blank?

	        correct_benefit_group = plan_year.benefit_groups.detect{|bg| data_row["Benefit Package/Benefit Group"].strip.downcase == bg.title.downcase.strip }
					benefit_group_assignment = select_benefit_group_assignment(data_row["Benefit Package/Benefit Group"], census_employee)

					if benefit_group_assignment.blank?
						benefit_group_assignment = census_employee.benefit_group_assignments.new(benefit_group: correct_benefit_group, start_on: benefit_begin_date)
						benefit_group_assignment.save!
						benefit_group_assignment.make_active
					end

					employee_role = Factories::EnrollmentFactory.construct_employee_role(nil,census_employee,person_details).first
					employee_role.benefit_group_id = benefit_group_assignment.benefit_group_id
					employee_role.save!

					subscriber = employee_role.person
					##  Give the subscriber the correct HBX ID.
					subscriber.hbx_id = data_row["HBX ID"]
					subscriber.save

					6.times do |i|
						if data_row["HBX ID (Dep #{i+1})"] != nil
							dependent = find_dependent(data_row["SSN (Dep #{i+1})"].to_s.gsub("-",""), data_row["DOB (Dep #{i+1})"],
								data_row["First Name (Dep #{i+1})"],data_row["Middle Name (Dep #{i+1})"],data_row["Last Name (Dep #{i+1})"])
							dependent.hbx_id = data_row["HBX ID (Dep #{i+1})"]
							dependent.save
						end
					end


    start_date = format_date(data_row["Benefit Begin Date"])
		plan = Plan.where(hios_id: data_row["HIOS ID"], active_year: data_row["Plan Year"].strip).first

		if plan.blank?
			raise "Unable to find plan with HIOS ID #{data_row["HIOS ID"]} for year #{data_row["Plan Year"].strip}"
		end


    family = subscriber.primary_family
		hh = family.active_household
		ch = hh.immediate_family_coverage_household
		en = hh.new_hbx_enrollment_from({
			coverage_household: ch,
			employee_role: employee_role,
			benefit_group: benefit_group_assignment.benefit_group,
			benefit_group_assignment: benefit_group_assignment
			})
		en.effective_on = start_date
		en.external_enrollment = true
		en.hbx_enrollment_members.each do |mem|
			mem.eligibility_date = start_date
			mem.coverage_start_on = start_date
		end

		en.carrier_profile_id = plan.carrier_profile_id
	  en.plan_id = plan.id
		en.aasm_state =  "coverage_selected"
		en.coverage_kind = 'health'

	  en.save!

		true
	# rescue Exception=>e
	# 	puts e.inspect
	# 	puts "-"*100
	# 	#puts e.backtrace
	# end
end
