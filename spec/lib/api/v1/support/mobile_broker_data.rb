module MobileBrokerData
  shared_context 'broker_data' do
    attr_reader :mikes_organization, :mikes_employer, :mikes_family, :carols_organization, :carols_employer, :carols_family, :mikes_plan_year, :carols_plan_year, :carols_benefit_group

    # Mikes Factory records
    let!(:mikes_broker_org) { FactoryGirl.create(:organization) }
    let!(:mikes_broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: mikes_broker_org) }
    let!(:mikes_broker_role) { FactoryGirl.create(:broker_role, broker_agency_profile_id: mikes_broker_agency_profile.id) }
    let!(:mikes_broker_agency_account) { FactoryGirl.create(:broker_agency_account, broker_agency_profile: mikes_broker_agency_profile, writing_agent: mikes_broker_role, family: mikes_family) }
    let(:mikes_employer_profile) { mikes_employer.tap do |employer|
      employer.organization = mikes_organization
      employer.broker_agency_profile = mikes_broker_agency_profile
      employer.broker_role_id = mikes_broker_role._id
      employer.broker_agency_accounts = [mikes_broker_agency_account]
      employer.plan_years = [mikes_plan_year]
    end
    mikes_employer.save
    mikes_employer
    }

    let!(:mikes_broker) { FactoryGirl.create(:user, person: mikes_broker_role.person, roles: [:broker]) }
    let!(:mikes_employer_profile_person) { FactoryGirl.create(:person, first_name: "Fring") }
    let!(:mikes_employer_profile_staff_role) { FactoryGirl.create(:employer_staff_role, person: mikes_employer_profile_person, employer_profile_id: mikes_employer_profile.id) }
    let!(:mikes_employer_profile_user) { double("user", :has_broker_agency_staff_role? => false, :has_hbx_staff_role? => false, :has_employer_staff_role? => true, :has_broker_role? => false, :person => mikes_employer_profile_staff_role.person) }

    #Carols Factory records
    let!(:carols_broker_org) { FactoryGirl.create(:organization, legal_name: "Alphabet Agency", dba: "ABCD etc") }
    let!(:carols_broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: carols_broker_org) }
    let!(:carols_broker_role) { FactoryGirl.create(:broker_role, broker_agency_profile_id: carols_broker_agency_profile.id) }
    let!(:carols_broker_agency_account) { FactoryGirl.create(:broker_agency_account, broker_agency_profile: carols_broker_agency_profile, writing_agent: carols_broker_role, family: carols_family) }
    let!(:person) { carols_broker_role.person.tap do |person|
      person.first_name = "Walter"
      person.last_name = "White"
    end
    carols_broker_role.person.save
    carols_broker_role.person
    }

    let!(:carols_broker) { FactoryGirl.create(:user, person: carols_broker_role.person, roles: [:broker]) }
    let!(:carols_employer_profile) { carols_employer.tap do |carol|
      carol.organization = carols_organization
      carol.broker_agency_profile = carols_broker_agency_profile
      carol.broker_role_id = carols_broker_role._id
      carol.broker_agency_accounts = [carols_broker_agency_account]
    end
    carols_employer.save
    carols_employer
    }
    let!(:carols_employer_profile_person) { FactoryGirl.create(:person, first_name: "Pinkman") }
    let!(:carols_employer_profile_staff_role) { FactoryGirl.create(:employer_staff_role, person: carols_employer_profile_person, employer_profile_id: carols_employer_profile.id) }
    let!(:carols_employer_profile_user) { double("user", :has_broker_agency_staff_role? => false, :has_hbx_staff_role? => false, :has_employer_staff_role? => true, :has_broker_role? => false, :person => carols_employer_profile_staff_role.person) }
    let!(:carols_renewing_plan_year) { FactoryGirl.create(:renewing_plan_year, aasm_state: "renewing_draft", employer_profile: carols_employer, benefit_groups: [carols_benefit_group]) }

    #HBX Admin Factories
    let(:hbx_person) { FactoryGirl.create(:person, first_name: "Jessie") }
    let!(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: hbx_person) }
    let!(:hbx_user) { double("user", :has_broker_agency_staff_role? => false, :has_hbx_staff_role? => true, :has_employer_staff_role? => false, :has_broker_role? => false, :person => hbx_staff_role.person) }


    before(:each) do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
      sign_in(user)
    end
  end
end