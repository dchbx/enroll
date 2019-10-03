require "rails_helper"

describe FamilyPolicy, "given a user who has no properties" do
  let(:primary_person_id) { double }
  let(:family) { instance_double(Family) }
  let(:user) { instance_double(User, :person => nil) }

  subject { FamilyPolicy.new(user, family) }

  it "can't show" do
    expect(subject.show?).to be_falsey
  end
end

describe FamilyPolicy, "given a user who is the primary member" do
  let(:primary_person_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member) }
  let(:person) { instance_double(Person, :id => primary_person_id) }
  let(:user) { instance_double(User, :person => person) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id) } 

  subject { FamilyPolicy.new(user, family) }

  it "can show" do
    expect(subject.show?).to be_truthy
  end
end

describe FamilyPolicy, "given a family with an active broker agency account", :dbclean => :after_each do
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:person) { FactoryBot.create(:person, :with_family)}
  let(:family) { (person.primary_family) }
  let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1', assigned_site: site) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :active_broker_staff_roles => [broker_agency_staff_role], :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_staff_role) { instance_double(BrokerAgencyStaffRole, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_agency_account) {FactoryBot.create(:broker_agency_account, broker_agency_profile_id: broker_agency_profile_id_account, writing_agent_id: broker_role.id, is_active: true)}

  subject { FamilyPolicy.new(user, family) }

  before(:each) do
    allow(broker_person).to receive(:broker_role).and_return nil
  end

  describe "when the user is an active member of the same broker agency as the account" do
    let(:broker_agency_profile_id_account) { broker_agency_profile.id }
    let(:user) { FactoryBot.create(:user, :person => person)}

    it "can show" do
      expect(subject.show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different broker agency from the account" do
    let(:broker_person_id) { double }
    let(:broker_agency_profile_id) { double }
    let(:broker_agency_profile_id_account) { double }
    let(:broker_person) { instance_double(Person, :id => broker_person_id, :active_broker_staff_roles => [broker_agency_staff_role], :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
    let(:user) { FactoryBot.create(:user, :person => broker_person)}

    it "can't show" do
      expect(subject.show?).to be_falsey
    end
  end
end

describe FamilyPolicy, "given a family where the primary has an active employer broker account", dbclean: :after_each do
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:organization)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:employer_profile)    { organization.employer_profile }
  let(:employee_role) {FactoryBot.create(:employee_role, employer_profile: employer_profile)}
  let(:person) { FactoryBot.create(:person, :with_family)}
  let(:family) { (person.primary_family) }
  let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1', assigned_site: site) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :active_broker_staff_roles => [broker_agency_staff_role], :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_staff_role) { instance_double(BrokerAgencyStaffRole, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_agency_account) {FactoryBot.create(:broker_agency_account, broker_agency_profile_id: broker_agency_profile_id_account, writing_agent_id: broker_role.id, is_active: true)}

  subject { FamilyPolicy.new(user, family) }

  before(:each) do
    allow(broker_person).to receive(:broker_role).and_return nil
  end

  describe "when the user is an active member of the same broker agency as the account" do
    let(:broker_agency_profile_id_account) { broker_agency_profile.id }
    let(:user) { FactoryBot.create(:user, :person => person)}

    it "can show" do
      expect(subject.show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different broker agency from the account" do
    let(:broker_agency_profile_id_account) { double }
    let(:employee_person) { employee_role.person }
    let(:user) { FactoryBot.create(:user, :person => employee_person)}

    it "can't show" do
      expect(subject.show?).to be_falsey
    end
  end
end

describe FamilyPolicy, "given a family where the primary has an active employer general agency account account" do
  let(:primary_person_id) { double }
  let(:ga_person_id) { double }
  let(:general_agency_profile_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => nil) }
  let(:employer_profile) { instance_double(EmployerProfile, :active_broker_agency_account => nil, :active_general_agency_account => general_agency_account) }
  let(:employee_role) { instance_double(EmployeeRole, :employer_profile => employer_profile) }
  let(:person) { instance_double(Person, :id => primary_person_id, :active_employee_roles => [employee_role], :active_broker_staff_roles => [broker_agency_staff_role]) }
  let(:broker_agency_staff_role) { instance_double(BrokerAgencyStaffRole, :benefit_sponsors_broker_agency_profile_id => '1234') }
  let(:user) { instance_double(User, :person => ga_person) }
  let(:ga_person) { instance_double(Person, :id => ga_person_id, :broker_role => nil, :active_general_agency_staff_roles => [general_agency_staff_role], :active_broker_staff_roles => [broker_agency_staff_role], :hbx_staff_role => nil) }
  let(:general_agency_staff_role) { instance_double(GeneralAgencyStaffRole, :benefit_sponsors_general_agency_profile_id => general_agency_profile_id) }
  let(:general_agency_account) { instance_double(SponsoredBenefits::Accounts::GeneralAgencyAccount, :benefit_sponsrship_general_agency_profile_id => general_agency_account_profile_id) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }

  subject { FamilyPolicy.new(user, family) }

  describe "when the user is an active member of the same general agency as the account" do
    let(:general_agency_account_profile_id) { general_agency_profile_id }

    it "can show" do
      expect(subject.show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different general agency from the account" do
    let(:general_agency_account_profile_id) { double }

    it "can't show" do
      expect(subject.show?).to be_falsey
    end
  end
end

describe FamilyPolicy, "given a user who has the modify family permission" do
  let(:primary_person_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => nil) }
  let(:person) { instance_double(Person, :id => primary_person_id) }
  let(:user) { instance_double(User, :person => permissioned_person) }
  let(:permissioned_person) { instance_double(Person, :id => double, :hbx_staff_role => hbx_staff_role) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }
  let(:hbx_staff_role) { instance_double(HbxStaffRole, :permission => permission) }
  let(:permission) { instance_double(Permission, :modify_family => true) }

  subject { FamilyPolicy.new(user, family) }

  it "can show" do
    expect(subject.show?).to be_truthy
  end

  it "can can_view_entire_family_enrollment_history" do
    expect(subject.can_view_entire_family_enrollment_history?).to be_truthy
  end
end

describe FamilyPolicy, 'given a family with an active broker with only broker role' do
  let(:primary_person_id) { double }
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => broker_agency_account) }
  let(:person) { instance_double(Person, :id => primary_person_id, :active_employee_roles => []) }
  let(:user) { instance_double(User, :person => broker_person) }
  let(:broker_role) { instance_double(BrokerRole, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :broker_role => broker_role, :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_account) { instance_double(BenefitSponsors::Accounts::BrokerAgencyAccount, :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id_account) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }


  subject { FamilyPolicy.new(user, family) }

  before(:each) do
    allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account
    allow(broker_person).to receive(:active_broker_staff_roles).and_return []
  end

  context 'when the user is an active member of the same broker agency as the account' do
    let(:broker_agency_profile_id_account) { broker_agency_profile_id }

    it 'can show' do
      allow(broker_person).to receive(:active_broker_staff_roles).and_return []
      expect(subject.show?).to be_truthy
    end
  end
end

describe 'can_broker_modify_family' do

  let(:person) { FactoryBot.create(:person, :with_family) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { person.primary_family }
  let(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
  let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
  let(:broker_agency_account) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: broker_role.id, is_active: true) }

  subject { FamilyPolicy.new(user, family) }

  context 'person with only broker role' do

    it 'can modify family' do
      allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account
      expect(subject.can_broker_modify_family?(broker_role, nil)).to be_truthy
    end
  end

  context 'person with only broker staff role' do

    let!(:broker_agency_staff_role1) { FactoryBot.create(:broker_agency_staff_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
    let!(:broker_agency_staff_role2) { FactoryBot.create(:broker_agency_staff_role, aasm_state: 'pending', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }

    it 'can modify family' do
      allow(family).to receive(:active_broker_agency_account).and_return broker_agency_account
      expect(subject.can_broker_modify_family?(nil, person.active_broker_staff_roles)).to be_truthy
    end
  end
end
