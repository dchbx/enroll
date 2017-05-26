require 'csv'

filename = "Redmine-7996_enrollments.csv"

def select_benefit_package(title, benefit_coverage_period)
	benefit_coverage_period.benefit_packages.each do |benefit_package|
		if benefit_package.title == title
			return benefit_package
		end
	end
end

def select_benefit_coverage_period(organization,effective_date)
	benefit_coverage_periods = organization.hbx_profile.benefit_sponsorship.benefit_coverage_periods
	benefit_coverage_periods.each do |bcp|
		start_date = bcp.start_on
		end_date = bcp.end_on
		period = (start_date..end_date)
		if period.include?(effective_date)
			return bcp
		end
	end
end

def format_date(date)
	date = Date.strptime(date,'%m/%d/%Y')
end

def create_person_details(subscriber_params)
	person_details = Hash.new
	person_details["name_pfx"] = subscriber_params["name_pfx"]
	person_details["first_name"] = subscriber_params["first_name"]
	person_details["middle_name"] = subscriber_params["middle_name"]
	person_details["last_name"] = subscriber_params["last_name"]
	person_details["name_sfx"] = subscriber_params["name_sfx"]
	person_details["gender"] = subscriber_params["gender"]
	person_details["ssn"] = subscriber_params["ssn"]
	person_details["dob"] = subscriber_params["dob"]
	person_details = {:person => person_details}
	return person_details
end

def find_dependent(ssn,dob,first_name,middle_name,last_name)
	dob = format_date(dob)
	person = Person.match_by_id_info(:ssn=> ssn, :dob => dob, :first_name => first_name, :last_name => last_name).first
	if person == nil
		return ArgumentError.new("dependent does not exist for provided person details")
	else
		return person
	end
end

CSV.foreach(filename, headers: :true) do |row|
	data_row = row.to_hash
	subscriber = Person.where(hbx_id: data_row['HBX ID']).first
	subscriber_by_id_info = Person.match_by_id_info(:ssn=> data_row["SSN"].gsub("-",""), 
													:dob => format_date(data_row["DOB"]), 
													:first_name => data_row["First Name"], 
													:last_name => data_row["Last Name"]).first
	if subscriber == nil && subscriber_by_id_info != nil
		puts "Potential HBX ID discrepancy. Please resolve prior to enrollment import."
		puts "#{data_row['HBX ID']} does not exist in Enroll."
		puts "Existing Person: #{subscriber_by_id_info.hbx_id} - #{subscriber_by_id_info.first_name} #{subscriber_by_id_info.last_name} - #{subscriber_by_id_info.dob} - #{subscriber_by_id_info.ssn}"
		next
	elsif subscriber.hbx_id != subscriber_by_id_info.hbx_id
		puts "Potential HBX ID discrepancy. Please resolve prior to enrollment import."
		puts "Person 1: #{subscriber.hbx_id} - #{subscriber.first_name} #{subscriber.last_name} - #{subscriber.dob} - #{subscriber.ssn}"
		puts "Person 2: #{subscriber_by_id_info.hbx_id} - #{subscriber_by_id_info.first_name} #{subscriber_by_id_info.last_name} - #{subscriber_by_id_info.dob} - #{subscriber_by_id_info.ssn}"
		next
	elsif subscriber.blank?
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
		consumer_role = Factories::EnrollmentFactory.construct_consumer_role(person_details,nil)
		consumer_role.save
		subscriber = consumer_role.person
		## Add contact info
			unless data_row["Address Kind"].blank?
				subscriber.addresses.build(:kind => data_row["Address Kind"], 
										   :address_1 => data_row["Address 1"],
										   :address_2 => data_row["Address 2"],
										   :city => data_row["City"], 
										   :state => data_row["State"], 
										   :zip => data_row["Zip"].to_s)
				subscriber.save
			end
			unless data_row["Phone Type"].blank?
				subscriber.phones.build(:kind => data_row["Phone Type"],
										:full_phone_number => data_row["Phone Number"].to_s.gsub("(","").gsub(")","").gsub("-",""))
				subscriber.save
			end
			unless data_row["Email Kind"].blank?
				subscriber.emails.build(:kind => data_row["Email Kind"],
										:address => data_row["Email Address"])
				subscriber.save
			end
	end  
	
	if subscriber.present? && subscriber.consumer_role.blank?
		consumer_role = Factories::EnrollmentFactory.build_consumer_role(subscriber,false)
		consumer_role.save
	else
		consumer_role = subscriber.consumer_role
	end
	
	family = subscriber.primary_family
	hh = family.active_household
	ch = hh.immediate_family_coverage_household

	6.times do |i|
		if data_row["HBX ID (Dep #{i+1})"] != nil
			dependent = find_dependent(data_row["SSN (Dep #{i+1})"].to_s.gsub("-",""), data_row["DOB (Dep #{i+1})"],
				data_row["First Name (Dep #{i+1})"],data_row["Middle Name (Dep #{i+1})"],data_row["Last Name (Dep #{i+1})"])
			if dependent.blank? || dependent.to_s == "dependent does not exist for provided person details"
				begin
					dependent = OpenStruct.new
					dependent.first_name = data_row["First Name (Dep #{i+1})"]
					dependent.middle_name = data_row["Middle Name (Dep #{i+1})"]
					dependent.last_name = data_row["Last Name (Dep #{i+1})"]
					dependent.ssn = data_row["SSN (Dep #{i+1})"].to_s.gsub("-","")
					dependent.dob = format_date(data_row["DOB (Dep #{i+1})"]).strftime("%Y-%m-%d")
					dependent.employee_relationship = data_row["Relationship (Dep #{i+1})"]
				rescue Exception=>e
					puts e.inspect
				end
				family_member = Factories::EnrollmentFactory.initialize_dependent(family,subscriber,dependent)
				family_member.save
				family_member.person.gender = data_row["Gender (Dep #{i+1})"]
				family_member.person.save
				ch_member = ch.add_coverage_household_member(family_member)
				ch_member.save
				ch.save
				family.save
			end
			dependent = find_dependent(data_row["SSN (Dep #{i+1})"].to_s.gsub("-",""), data_row["DOB (Dep #{i+1})"],
				data_row["First Name (Dep #{i+1})"],data_row["Middle Name (Dep #{i+1})"],data_row["Last Name (Dep #{i+1})"])
			dependent.hbx_id = data_row["HBX ID (Dep #{i+1})"]
			dependent.save
		end
	end

	start_date = format_date(data_row["Benefit Begin Date"])
	
	hbx_organization = Organization.where(hbx_profile: {"$ne" => nil}).first
	benefit_coverage_period = select_benefit_coverage_period(hbx_organization,start_date)
	
	plan = Plan.where(hios_id: data_row["HIOS ID"], active_year: data_row["Plan Year"].strip).first
	if plan.blank?
		raise "Unable to find plan with HIOS ID #{data_row["HIOS ID"]} for year #{data_row["Plan Year"].strip}"
	end

	benefit_package = select_benefit_package(data_row["Benefit Package/Benefit Group"],benefit_coverage_period)
	en = hh.new_hbx_enrollment_from({
			coverage_household: ch,
			consumer_role: consumer_role,
			benefit_package: benefit_package,
			submitted_at: data_row["Date Plan Selected"].to_time
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
	en.coverage_kind = plan.coverage_kind
	en.hbx_id = data_row["Enrollment Group ID"]

	en.save!

	true
end