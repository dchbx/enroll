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

describe FamilyPolicy, "given a family with an active broker agency account" do
  let(:primary_person_id) { double }
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => broker_agency_account) }
  let(:person) { instance_double(Person, :id => primary_person_id, :active_employee_roles => []) }
  let(:user) { instance_double(User, :person => broker_person) }
  let(:broker_role) { instance_double(BrokerRole, :broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :broker_role => broker_role, :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_account) { instance_double(BrokerAgencyAccount, :broker_agency_profile_id => broker_agency_profile_id_account) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }

  subject { FamilyPolicy.new(user, family) }

  describe "when the user is an active member of the same broker agency as the account" do
    let(:broker_agency_profile_id_account) { broker_agency_profile_id }

    it "can show" do
      expect(subject.show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different broker agency from the account" do
    let(:broker_agency_profile_id_account) { double }

    it "can't show" do
      expect(subject.show?).to be_falsey
    end
  end
end

describe FamilyPolicy, "given a family where the primary has an active employer broker account" do
  let(:primary_person_id) { double }
  let(:broker_person_id) { double }
  let(:broker_agency_profile_id) { double }
  let(:family) { instance_double(Family, :primary_applicant => primary_member, :active_broker_agency_account => nil) }
  let(:employer_profile) { instance_double(EmployerProfile, :active_broker_agency_account => broker_agency_account) }
  let(:employee_role) { instance_double(EmployeeRole, :employer_profile => employer_profile) }
  let(:person) { instance_double(Person, :id => primary_person_id, :active_employee_roles => [employee_role]) }
  let(:user) { instance_double(User, :person => broker_person) }
  let(:broker_role) { instance_double(BrokerRole, :broker_agency_profile_id => broker_agency_profile_id) }
  let(:broker_person) { instance_double(Person, :id => broker_person_id, :broker_role => broker_role, :active_general_agency_staff_roles => [], :hbx_staff_role => nil) }
  let(:broker_agency_account) { instance_double(BrokerAgencyAccount, :broker_agency_profile_id => broker_agency_profile_id_account) }
  let(:primary_member) { instance_double(FamilyMember, :person_id => primary_person_id, :person => person) }

  subject { FamilyPolicy.new(user, family) }

  describe "when the user is an active member of the same broker agency as the account" do
    let(:broker_agency_profile_id_account) { broker_agency_profile_id }

    it "can show" do
      expect(subject.show?).to be_truthy
    end
  end

  describe "when the user is an active member of a different broker agency from the account" do
    let(:broker_agency_profile_id_account) { double }

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
  let(:person) { instance_double(Person, :id => primary_person_id, :active_employee_roles => [employee_role]) }
  let(:user) { instance_double(User, :person => ga_person) }
  let(:ga_person) { instance_double(Person, :id => ga_person_id, :broker_role => nil, :active_general_agency_staff_roles => [general_agency_staff_role], :hbx_staff_role => nil) }
  let(:general_agency_staff_role) { instance_double(GeneralAgencyStaffRole, :general_agency_profile_id => general_agency_profile_id) }
  let(:general_agency_account) { instance_double(GeneralAgencyAccount, :general_agency_profile_id => general_agency_account_profile_id ) }
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

end
