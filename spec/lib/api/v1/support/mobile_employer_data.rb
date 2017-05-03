module MobileEmployerData
  shared_context 'employer_data' do
    let!(:employer_profile_cafe) { FactoryGirl.create(:employer_profile, legal_name: "Cafe Curioso") }
    let!(:employer_profile_salon) { FactoryGirl.create(:employer_profile, legal_name: "Moe's Hair Salon") }
    let!(:calender_year) { TimeKeeper.date_of_record.year + 1 }

    let!(:middle_of_prev_year) { Date.new(calender_year - 1, 6, 10) }

    let!(:shop_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:plan_year_start_on) { Date.new(calender_year, 1, 1) }
    let!(:plan_year_end_on) { Date.new(calender_year, 12, 31) }
    let!(:open_enrollment_start_on) { Date.new(calender_year - 1, 11, 1) }
    let!(:open_enrollment_end_on) { Date.new(calender_year - 1, 12, 10) }
    let!(:effective_date) { plan_year_start_on }

    ["cafe", "salon"].each do |id|
      employer_profile_id = "employer_profile_#{id}".to_sym
      plan_year_id = "plan_year_#{id}".to_sym
      let!(plan_year_id) {
        py = FactoryGirl.create(:plan_year,
                                start_on: plan_year_start_on,
                                end_on: plan_year_end_on,
                                open_enrollment_start_on: open_enrollment_start_on,
                                open_enrollment_end_on: open_enrollment_end_on,
                                employer_profile: send(employer_profile_id))

        blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
        white = FactoryGirl.build(:benefit_group, :with_valid_dental, title: "white collar", plan_year: py)
        py.benefit_groups = [blue, white]
        py.save
        py.update_attributes({:aasm_state => 'published'})
        py
      }
    end


    [{id: :barista, name: 'John', coverage_kind: "health", works_at: 'cafe', collar: "blue"},
     {id: :manager, name: 'Grace', coverage_kind: "health", works_at: 'cafe', collar: "white"},
     {id: :janitor, name: 'Bob', coverage_kind: "dental", works_at: 'cafe', collar: "blue"},
     {id: :hairdresser, name: 'Tatiana', coverage_kind: "health", works_at: 'salon', collar: "blue"}
    ].each_with_index do |record, index|
      id = record[:id]
      name = record[:name]
      works_at = record[:works_at]
      coverage_kind = record[:coverage_kind]
      social_class = "#{record[:collar]} collar"
      employer_profile_id = "employer_profile_#{works_at}".to_sym
      plan_year_id = "plan_year_#{works_at}".to_sym
      census_employee_id = "census_employee_#{id}".to_sym
      employee_role_id = "employee_role_#{id}".to_sym
      benefit_group_assignment_id = "benefit_group_assignment_#{id}".to_sym
      shop_enrollment_id = "shop_enrollment_#{id}".to_sym
      get_benefit_group = -> (year) { year.benefit_groups.detect { |bg| bg.title == social_class } }

      let!(id) {
        FactoryGirl.create(:person, first_name: name, last_name: 'Smith',
                           dob: '1966-10-10'.to_date, ssn: rand.to_s[2..10])
      }

      let!(census_employee_id) {
        FactoryGirl.create(:census_employee, first_name: name, last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: "99966770#{index}", created_at: middle_of_prev_year, updated_at: middle_of_prev_year, hired_on: middle_of_prev_year)
      }

      let!(employee_role_id) {
        send(record[:id]).employee_roles.create(
            employer_profile: send(employer_profile_id),
            hired_on: send(census_employee_id).hired_on,
            census_employee_id: send(census_employee_id).id
        )
      }

      let!(benefit_group_assignment_id) {
        BenefitGroupAssignment.create({
                                          census_employee: send(census_employee_id),
                                          benefit_group: get_benefit_group.call(send(plan_year_id)),
                                          start_on: plan_year_start_on
                                      })
      }

      let!(shop_enrollment_id) {
        benefit_group = get_benefit_group.call(send(plan_year_id))
        bga_id = send(benefit_group_assignment_id).id
        FactoryGirl.create(:hbx_enrollment,
                           household: shop_family.latest_household,
                           coverage_kind: coverage_kind,
                           effective_on: effective_date,
                           enrollment_kind: "open_enrollment",
                           kind: "employer_sponsored",
                           submitted_at: effective_date - 10.days,
                           benefit_group_id: benefit_group.id,
                           employee_role_id: send(employee_role_id).id,
                           benefit_group_assignment_id: bga_id
        )
      }

      let!(:broker_role) { FactoryGirl.create(:broker_role) }
      let!(:person) { double("person", broker_role: broker_role, first_name: "Brunhilde") }
      let!(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :person => person) }
      let!(:organization) {
        o = FactoryGirl.create(:employer)
        a = o.primary_office_location.address
        a.address_1 = '500 Employers-Api Avenue'
        a.address_2 = '#555'
        a.city = 'Washington'
        a.state = 'DC'
        a.zip = '20001'
        o.primary_office_location.phone = Phone.new(:kind => 'main', :area_code => '202', :number => '555-9999')
        o.save
        o
      }
      let!(:broker_agency_profile) {
        profile = FactoryGirl.create(:broker_agency_profile, organization: organization)
        broker_role.broker_agency_profile_id = profile.id
        profile
      }
      let!(:broker_agency_account) {
        FactoryGirl.build(:broker_agency_account, broker_agency_profile: broker_agency_profile)
      }
      let!(:broker_agency_account2) {
        FactoryGirl.build(:broker_agency_account, writing_agent: broker_role)
      }
      let (:employer_profile) do
        e = FactoryGirl.create(:employer_profile, organization: organization)
        e.broker_agency_accounts << broker_agency_account
        e.save
        e
      end

      let (:employer_profile2) do
        e = FactoryGirl.create(:employer_profile, organization: organization)
        e.broker_agency_accounts << broker_agency_account2
        e.save
        e
      end

        let(:staff_user) { FactoryGirl.create(:user) }
        let(:staff) do
          s = FactoryGirl.create(:person, :with_work_email, :male)
          s.user = staff_user
          s.first_name = "Seymour"
          s.emails.clear
          s.emails << ::Email.new(:kind => 'work', :address => 'seymour@example.com')
          s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0000')
          s.save
          s
        end

        let(:staff_user2) { FactoryGirl.create(:user) }
        let(:staff2) do
          s = FactoryGirl.create(:person, :with_work_email, :male)
          s.user = staff_user2
          s.first_name = "Beatrice"
          s.emails.clear
          s.emails << ::Email.new(:kind => 'work', :address => 'beatrice@example.com')
          s.phones << ::Phone.new(:kind => 'work', :area_code => '202', :number => '555-0001')
          s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0002')
          s.save
          s
        end

      let!(:benefit_group_assignment) {send(benefit_group_assignment_id)}
      let!(:hbx_enrollment) {send(shop_enrollment_id)}

      before do
        allow(send(employee_role_id)).to receive(:benefit_group).and_return(benefit_group_assignment.benefit_group)
        allow(send(census_employee_id)).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
        allow(send(shop_enrollment_id)).to receive(:employee_role).and_return(send(employee_role_id))
        @employer = Api::V1::Mobile::EmployerUtil.new
      end
    end
  end
end