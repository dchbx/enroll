require "rails_helper"

describe AccessPolicies::EmployerProfile, :dbclean => :after_each do
  subject { AccessPolicies::EmployerProfile.new(user) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:controller) { Employers::EmployerProfilesController.new }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }

  context "authorize show" do
    context "for an admin user on any employer profile" do
      let(:person) { FactoryGirl.create(:person, :with_hbx_staff_role) }

      it "should authorize" do
        expect(subject.authorize_show(employer_profile, controller)).to be_truthy
      end
    end

    context "for an employer staff user of employer profile" do
     let(:person) { FactoryGirl.create(:person, :with_employer_staff_role) }
     let(:employer_profile) { EmployerProfile.find(person.employer_staff_roles.first.employer_profile_id)}

      it "should authorize" do
        expect(subject.authorize_show(employer_profile, controller)).to be_truthy
      end
    end

    context "has broker role of employer profile" do
      let(:user) { FactoryGirl.create(:user, person: person, roles: ["broker"]) }
      let(:person) { FactoryGirl.create(:person) }
      let(:broker_role) { FactoryGirl.create(:broker_role, person: person) }
      let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, primary_broker_role: broker_role) }

      it "should authorize" do
        broker_role.save
        broker_agency_account = BrokerAgencyAccount.create(employer_profile: employer_profile, start_on: TimeKeeper.date_of_record, broker_agency_profile_id: broker_agency_profile.id, writing_agent_id: broker_role.id )
        expect(subject.authorize_show(employer_profile, controller)).to be_truthy
      end
    end

    context "has no employer hbx or broker roles" do
      let(:person) { FactoryGirl.create(:person) }

      it "should redirect you to new" do
         expect(controller).to receive(:redirect_to_new)
         subject.authorize_show(employer_profile, controller)
      end
    end

    context "has an employer staff role for another employer" do
      let(:person) { FactoryGirl.create(:person, :with_employer_staff_role) }

      it "should redirect to your first allowed employer profile" do
         expect(controller).to receive(:redirect_to_first_allowed)
         subject.authorize_show(employer_profile, controller)
      end
    end

    context "has broker role of another employer profile" do
      let(:user) { FactoryGirl.create(:user, person: person, roles: ["broker"]) }
      let(:person) { FactoryGirl.create(:person) }
      let(:broker_role) { FactoryGirl.create(:broker_role, person: person) }
      let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, primary_broker_role: broker_role) }
      let(:another_employer_profile) { FactoryGirl.create(:employer_profile) }

      it "should redirect you to new" do
        broker_role.save
        broker_agency_account = BrokerAgencyAccount.create(employer_profile: another_employer_profile, start_on: TimeKeeper.date_of_record, broker_agency_profile_id: broker_agency_profile.id, writing_agent_id: broker_role.id )
        expect(controller).to receive(:redirect_to_new)
        subject.authorize_show(employer_profile, controller)
      end
    end
  end

  context "authorize index" do
    context "for an admin user" do
      let(:person) {FactoryGirl.create(:person, :with_hbx_staff_role) }

      it "should authorize" do
        expect(subject.authorize_index(employer_profile, controller)).to be_truthy
      end
    end

    context "has no employer hbx or broker roles" do
      let(:person) { FactoryGirl.create(:person) }

      it "should redirect you to new" do
         expect(controller).to receive(:redirect_to_new)
         subject.authorize_show(employer_profile, controller)
      end
    end

    context "has broker role of employer profile" do
      let(:user) { FactoryGirl.create(:user, person: person, roles: ["broker"]) }
      let(:person) { FactoryGirl.create(:person) }
      let(:broker_role) { FactoryGirl.create(:broker_role, person: person) }
      let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, primary_broker_role: broker_role) }

      it "should authorize" do
        broker_role.save
        broker_agency_account = BrokerAgencyAccount.create(employer_profile: employer_profile, start_on: TimeKeeper.date_of_record, broker_agency_profile_id: broker_agency_profile.id, writing_agent_id: broker_role.id )
        expect(subject.authorize_index(employer_profile, controller)).not_to be_truthy
        expect(controller).not_to receive(:redirect_to_new)
      end
    end
  end

  context "authorize edit" do
    context "for an admin user" do
      let(:person) {FactoryGirl.create(:person, :with_hbx_staff_role) }

      it "should authorize" do
        expect(subject.authorize_edit(employer_profile, controller)).to be_truthy
      end
    end

    context "for an employer staff user of employer profile" do
     let(:person) { FactoryGirl.create(:person, :with_employer_staff_role) }
     let(:employer_profile) { EmployerProfile.find(person.employer_staff_roles.first.employer_profile_id)}

      it "should authorize" do
        expect(subject.authorize_edit(employer_profile, controller)).to be_truthy
      end
    end

    context "has broker role of employer profile" do
      let(:user) { FactoryGirl.create(:user, person: person, roles: ["broker"]) }
      let(:person) { FactoryGirl.create(:person) }
      let(:broker_role) { FactoryGirl.create(:broker_role, person: person) }
      let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, primary_broker_role: broker_role) }

      it "should authorize" do
        broker_role.save
        broker_agency_account = BrokerAgencyAccount.create(employer_profile: employer_profile, start_on: TimeKeeper.date_of_record, broker_agency_profile_id: broker_agency_profile.id, writing_agent_id: broker_role.id )
        expect(subject.authorize_edit(employer_profile, controller)).to be_truthy
      end
    end

    context "have general_agency_staff of employer_profile" do
      let(:user) { FactoryGirl.create(:user, person: person, roles: ["general_agency_staff"]) }
      let(:person) { FactoryGirl.create(:person, :with_general_agency_staff_role) }
      let(:general_agency_staff) { person.general_agency_staff_roles.last }
      let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }

      it "should authorize" do
        allow(general_agency_staff).to receive(:general_agency_profile).and_return general_agency_profile
        allow(general_agency_profile).to receive(:employer_clients).and_return([employer_profile])
        expect(subject.authorize_edit(employer_profile, controller)).to be_truthy
      end
    end

    context "is staff of employer" do
      let(:person) { FactoryGirl.create(:person) }

      it "should authorize" do
        allow(Person).to receive(:staff_for_employer).and_return([person])
        expect(subject.authorize_edit(employer_profile, controller)).to be_truthy
      end
    end

    context "has no employer hbx or broker roles" do
      let(:person) { FactoryGirl.create(:person) }

      it "should redirect you to new" do
        expect(controller).to receive(:redirect_to_new)
        subject.authorize_edit(employer_profile, controller)
      end
    end
  end
end
