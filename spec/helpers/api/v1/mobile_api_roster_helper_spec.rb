require "rails_helper"

RSpec.describe Api::V1::MobileApiRosterHelper, dbclean: :after_each do

	
  let!(:calendar_year)              { TimeKeeper.date_of_record.year }
  let!(:effective_date)         { Date.new(calendar_year, 1, 1) }
  let (:benefit_group) { FactoryGirl.create(:benefit_group, title: "Everyone") }
  let!(:shop_family)   { FactoryGirl.create(:family, :with_primary_family_member) }

  [{id: :employee, text: "Robert Anson Heinlein Esq.", dob: "1907-07-07", ssn: "444556666", gender: "male", hired_on: "2008-12-08"}, 
   {id: :owner, text: "Virginia Doris Heinlein", dob: "1916-04-22", ssn: "111223333", gender: "female", hired_on: "2006-11-11"}
  ].each_with_index do |record, index|  
      id = record[:id]
      first_name, middle_name, last_name, name_suffix = record[:text].split
      dob = record[:dob]
      ssn = record[:ssn]
      gender = record[:gender]
      hired_on = record[:hired_on]
      census_employee_id = "ce_#{id}".to_sym
      employee_role_id = "employee_role_#{id}".to_sym
      benefit_group_assignment_id = "benefit_group_assignment_#{id}".to_sym
      shop_enrollment_id = "shop_enrollment_#{id}".to_sym

      let!(id) { 
          FactoryGirl.create(:person, first_name: first_name, middle_name: middle_name, 
          					 last_name: last_name, name_sfx: name_suffix,
          					 dob: dob, ssn: ssn, gender: gender)
       }
  
      let!(census_employee_id) {
         FactoryGirl.create(:census_employee, first_name: first_name, middle_name: middle_name, 
          					 last_name: last_name, name_sfx: name_suffix,
          					 dob: dob, ssn: ssn, gender: gender, hired_on: hired_on)
       }

      let!(employee_role_id) {
          send(record[:id]).employee_roles.create(
            employer_profile: FactoryGirl.create(:employer_profile),
            hired_on: hired_on,
            census_employee_id: send(census_employee_id).id
          )
      }

      let!(benefit_group_assignment_id) {
        BenefitGroupAssignment.create({
          census_employee: send(census_employee_id),
          benefit_group: benefit_group,
          start_on: Date.parse("2014-01-01")
        })
      }

      enrollments_by_kind = Hash[[:health, :dental].map do |coverage_kind|
      	 [coverage_kind, "#{shop_enrollment_id}_#{coverage_kind}".to_sym]
      end]

      all_enrollments = {}

      enrollments_by_kind.each do |coverage_kind, enrollment_id|
      	let!(enrollment_id) { 
                              bga_id = send(benefit_group_assignment_id).id
                              enrollment = FactoryGirl.create(:hbx_enrollment,
                                                               household: shop_family.latest_household,
                                                               coverage_kind: coverage_kind,
                                                               effective_on: effective_date,
                                                               enrollment_kind: "open_enrollment",
                                                               kind: "employer_sponsored",
                                                               submitted_at: effective_date - 10.days,
                                                               benefit_group_id: benefit_group.id,
                                                               employee_role_id: send(employee_role_id).id,
                                                               benefit_group_assignment_id: bga_id,
                                                               aasm_state: "coverage_enrolled"
                                                             )

                              all_enrollments[benefit_group_assignment_id] ||= []
                              all_enrollments[benefit_group_assignment_id] << enrollment
                              enrollment
                            }
       end

        before do
          benefit_group_assignment = send(benefit_group_assignment_id)
          allow(send(employee_role_id)).to receive(:benefit_group).and_return(benefit_group_assignment.benefit_group)
          allow(send(census_employee_id)).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
          enrollments_by_kind.values do |enrollment_id|
          	allow(send(enrollment_id)).to receive(:employee_role).and_return(send(employee_role_id))
          end
          allow(send(benefit_group_assignment_id)).to receive(:hbx_enrollments).and_return(all_enrollments[benefit_group_assignment_id])
        end
  end


	context "Rendering employee" do
		it "should return correct JSON" do

			expect(ce_employee.active_benefit_group_assignment).to_not be nil
			expect(ce_employee.active_benefit_group_assignment.hbx_enrollments.count).to be > 0
			#print "\n\n>>> #{ce_employee.active_benefit_group_assignment.hbx_enrollments}\n\n"

			output = render_roster_employee(ce_employee, true)
			expect(output[:first_name]).to         eq "Robert" 
			expect(output[:middle_name]).to        eq "Anson" 
			expect(output[:last_name]).to          eq "Heinlein"
			expect(output[:name_suffix]).to        eq "Esq."
			expect(output[:gender]).to		       eq "male"
			expect(output[:date_of_birth]).to      eq Date.parse("1907-07-07")
			expect(output[:ssn_masked]).to         eq "***-**-6666"
			expect(output[:hired_on]).to 	       eq Date.parse("2008-12-08")
			expect(output[:id]).to 	  		       eq ce_employee.id
			expect(output[:is_business_owner]).to  be false

			#print "\n\n>>> #{output[:enrollments]}\n\n"
			expect(output[:enrollments][:active]["health"]).to_not be nil
			active_health = output[:enrollments][:active]["health"]
			expect(active_health[:status]).to      eq "Enrolled"

			#expect(output[:dependents].count).to   eq 1

		end
  end 

  #context "brady dependents" do
  #  include_context "BradyWorkAfterAll"
  #
  #  before :each do
  #    create_brady_census_families
  #    allow(mikes_census_employee).to receive(
  #      :active_benefit_group_assignment).and_return(@mikes_benefit_group_assignments)
  #  end
  #
  #  it "Should include dependents" do
  #    output = render_roster_employee(mikes_census_employee, true)
  #    expect(output[:dependents].count).to   eq 3 
  #    #three men living all together; but they are all alone
  #  end
  #
	#end

end

   #  "dependents": [
   #    {
   #      "first_name": "Tracey",
   #      "middle_name": "Davis",
   #      "last_name": "Jr.",
   #      "name_suffix": "1965-08-07",
   #      "date_of_birth": "***-**-9909",
   #      "ssn_masked": null,
   #      "gender": "F"
   #    },
   #   "enrollments": {
   #     "active": {
   #       "health": {
   #         "status": "Enrolled",
   #         "employer_contribution": 6963.9,
   #         "employee_cost": 3738.61,
   #         "total_premium": 10702.51,
   #         "plan_name": "KP DC Silver 2000/35",
   #         "plan_type": "HMO",
   #         "metal_level": "Silver",
   #         "benefit_group_name": "Other Employees",
   #         "plan_start_on": "2016-12-01"
   #       },
   #       "dental": {
   #         "status": "Enrolled",
   #         "employer_contribution": 6963.9,
   #         "employee_cost": 3738.61,
   #         "total_premium": 10702.51,
   #         "plan_name": "KP DC Silver 2000/35",
   #         "plan_type": "HMO",
   #         "metal_level": "Silver",
   #         "benefit_group_name": "Other Employees",
   #         "plan_start_on": "2016-12-01"
   #       }
   #     },
   #     "renewal": {
   #       "health": {
   #         "status": "Enrolled",
   #         "employer_contribution": 6963.9,
   #         "employee_cost": 3738.61,
   #         "total_premium": 10702.51,
   #         "plan_name": "KP DC Silver 2000/35",
   #         "plan_type": "HMO",
   #         "metal_level": "Silver",
   #         "benefit_group_name": "Other Employees",
   #         "plan_start_on": "2016-12-01"
   #       },
   #       "dental": {
   #         "status": "Enrolled",
   #         "employer_contribution": 6963.9,
   #         "employee_cost": 3738.61,
   #         "total_premium": 10702.51,
   #         "plan_name": "KP DC Silver 2000/35",
   #         "plan_type": "HMO",
   #         "metal_level": "Silver",
   #         "benefit_group_name": "Other Employees",
   #         "plan_start_on": "2016-12-01"
   #       }
   #     }

