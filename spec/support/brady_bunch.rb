module BradyBunch
  shared_context "BradyBunch" do
    def dob(num_years)
      Date.today - num_years.years
    end

    def build_brady_address
      FactoryGirl.build(:address,
        kind: "home",
        address_1:
        "4222 Clinton Way",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end

    let(:brady_addr) do
      FactoryGirl.build(:address,
        kind: "home",
        address_1:
        "4222 Clinton Way",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end

    def build_brady_phone 
      FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "7620799", extension: nil)
    end

    def female_brady(name, age)
      FactoryGirl.create(:female, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
    end

    def male_brady(name, age)
      FactoryGirl.create(:male, first_name: name, last_name: "Brady", dob: dob(age), addresses: [build_brady_address], phones: [build_brady_phone])
    end

    let(:brady_ph) {FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "7620799", extension: nil)}
    let(:last_name) {"Brady"}
    let(:mikes_age)   {40}
    let(:carols_age)  {35}
    let(:gregs_age)   {17}
    let(:marcias_age) {16}
    let(:peters_age)  {14}
    let(:jans_age)    {12}
    let(:bobbys_age)  {8}
    let(:cindys_age)  {6}
    let(:mike) { male_brady("Mike", mikes_age) }
    let(:carol) { female_brady("Carol", carols_age) }
    let(:greg) { male_brady("Greg", gregs_age) }
    let(:marcia) { female_brady("Marcia", marcias_age) }
    let(:peter) { male_brady("Peter", peters_age) }
    let(:jan) { female_brady("Jan", jans_age) }
    let(:bobby) { male_brady("Bobby", bobbys_age) }
    let(:cindy) { female_brady("Cindy", cindys_age) }
    let(:brady_daughters) {[marcia, jan, cindy]}
    let(:brady_sons) {[greg, peter, bobby]}
    let(:brady_children) {brady_sons + brady_daughters}
    let(:bradys) {[mike, carol, greg, marcia, peter, jan, bobby, cindy]}
    let!(:mikes_family) do
      mike.person_relationships.build(predecessor_id: mike.id, :successor_id => carol.id, :kind => "spouse", family_id: family.id)
      carol.person_relationships.build(successor_id: mike.id, :predecessor_id => carol.id, :kind => "spouse", family_id: family.id)
      brady_children.each do |child|
        mike.person_relationships.build(predecessor_id: mike.id, :successor_id => child.id, :kind => "parent", family_id: family.id)
        child.person_relationships.build(successor_id: mike.id, :predecessor_id => child.id, :kind => "child", family_id: family.id)
      end
      # mike.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "self")
      # mike.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "spouse")
      # brady_children.each do |child|
      #   mike.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      # end
      mike.save

      family = FactoryGirl.build(:family)
      family.add_family_member(mike, is_primary_applicant: true)
      (bradys - [mike]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      family
    end
    let!(:carols_family) do
      mike.person_relationships.build(predecessor_id: mike.id, :successor_id => carol.id, :kind => "spouse", family_id: family.id)
      carol.person_relationships.build(successor_id: mike.id, :predecessor_id => carol.id, :kind => "spouse", family_id: family.id)
      brady_children.each do |child|
        carol.person_relationships.build(predecessor_id: carol.id, :successor_id => child.id, :kind => "parent", family_id: family.id)
        child.person_relationships.build(successor_id: carol.id, :predecessor_id => child.id, :kind => "child", family_id: family.id)
      end
      # carol.person_relationships << PersonRelationship.new(relative_id: carol.id, kind: "self")
      # carol.person_relationships << PersonRelationship.new(relative_id: mike.id, kind: "spouse")
      # brady_children.each do |child|
      #   carol.person_relationships << PersonRelationship.new(relative_id: child.id, kind: "child")
      # end
      carol.save

      family = FactoryGirl.build(:family)
      family.add_family_member(carol, is_primary_applicant: true)
      (bradys - [carol]).each do |brady|
        family.add_family_member(brady)
      end
      family.save
      family
    end
    let(:mikes_coverage_household) {mikes_family.households.first.coverage_households.first}
    let(:carols_coverage_household) {carols_family.households.first.coverage_households.first}
  end

  shared_context "BradyWork" do
    include_context "BradyBunch"

    let(:mikes_work_addr) do
      FactoryGirl.build(:address,
        kind: "work",
        address_1:
        "6345 Reagan Road",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end
    let(:mikes_work_phone) {FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "5069292", extension: nil)}
    let(:mikes_office_location) do
      FactoryGirl.build(:office_location,
                        address: mikes_work_addr,
                        phone: mikes_work_phone
      )
    end
    let(:mikes_organization) do
      FactoryGirl.create(:organization,
                         legal_name: "Mike's Architects Limited",
                         dba: "MAL",
                         office_locations: [mikes_office_location]
      )
    end
    let(:mikes_hired_on) {1.year.ago.beginning_of_year.to_date}
    let!(:mikes_employer) {FactoryGirl.build(:employer_profile, organization: mikes_organization)}
    let(:mikes_benefit_group_assignments){FactoryGirl.build(:benefit_group_assignment)}
    let(:mikes_census_employee) do
      FactoryGirl.build(:census_employee,
                        first_name: mike.first_name,  last_name: mike.last_name,
                        dob: mike.dob, address: mike.address, hired_on: mikes_hired_on,
                        employer_profile_id: mikes_employer.id,
                        benefit_group_assignments: [mikes_benefit_group_assignments]
      )
    end
    let(:mikes_benefit_group) {FactoryGirl.build(:benefit_group, plan_year: nil)}
    let!(:mikes_plan_year) {FactoryGirl.create(:plan_year, employer_profile: mikes_employer, benefit_groups: [mikes_benefit_group])}

    let(:carols_work_addr) do
      FactoryGirl.build(:address,
        kind: "work",
        address_1:
        "1321 Carter Court",
        address_2: nil,
        city: "Washington",
        state: "DC",
        zip: "20011"
      )
    end
    let(:carols_work_ph) {FactoryGirl.build(:phone, kind: "home", area_code: "202", number: "6109987", extension: nil)}
    let(:carols_office_location) do
      FactoryGirl.build(:office_location,
                        address: carols_work_addr,
                        phone: carols_work_phone
      )
    end
    let(:carols_hired_on) {1.year.ago.beginning_of_year.to_date}
    let(:carols_employer) {FactoryGirl.build(:employer_profile)}
    let(:carols_organization) do
      FactoryGirl.create(:organization,
                         legal_name: "Care Real S Tates",
                         dba: "CRST",
                         office_locations: [carols_office_location],
                         employer_profile: carols_employer
      )
    end
    let(:carols_benefit_group_assignments){FactoryGirl.build(:benefit_group_assignment)}
    let(:carols_census_employee) do
      FactoryGirl.build(:employer_census_employee,
                        first_name: carol.first_name,  last_name: carol.last_name,
                        dob: carol.dob, address: carol.address, hired_on: carols_hired_on,
                        employer_profile_id: carols_employer.id,
                        benefit_group_assignments: [carols_benefit_group_assignments]
      )
    end
    let(:carols_benefit_group) {FactoryGirl.build(:benefit_group, plan_year: nil)}
    let!(:carols_plan_year) {FactoryGirl.create(:plan_year, employer_profile: carols_employer, benefit_groups: [carols_benefit_group])}
  end
end
