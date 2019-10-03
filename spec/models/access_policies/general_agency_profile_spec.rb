require "rails_helper"

describe AccessPolicies::GeneralAgencyProfile, :dbclean => :after_each do
  subject { AccessPolicies::GeneralAgencyProfile.new(user) }
  let(:broker_controller) { BrokerAgencies::ProfilesController.new }
  let(:ga_controller) { GeneralAgencies::ProfilesController.new }
  let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile) }

  context "authorize new" do
    let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, aasm_state: 'active', is_primary: true) }
    let(:person) { general_agency_staff_role.person }
    let(:user) { FactoryBot.create(:user, :general_agency_staff, person: person) }

    it "should redirect" do
      expect(ga_controller).to receive(:redirect_to_show)
      subject.authorize_new(ga_controller)
    end
  end

  context "authorize index" do
    context "for an admin user" do
      let(:user) { FactoryBot.create(:user, person: person) }
      let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }

      it "should authorize" do
        expect(subject.authorize_index(ga_controller)).to be_truthy
      end
    end

    context "for a broker_role" do
      let(:person) { FactoryBot.create(:person) }
      let(:user) { FactoryBot.create(:user, :broker, person: person) }

      it "should authorize" do
        expect(subject.authorize_index(ga_controller)).to be_truthy
      end
    end

    context "for csr user" do
      let(:person) { FactoryBot.create(:person) }
      let(:user) { FactoryBot.create(:user, :csr, person: person) }

      it "should authorize" do
        expect(subject.authorize_index(ga_controller)).to be_truthy
      end
    end

    context "for normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "should be redirect" do
        expect(ga_controller).to receive(:redirect_to_new)
        subject.authorize_index(ga_controller)
      end
    end

    context "for normal user with general_agency_profile" do
      let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, aasm_state: 'active', is_primary: true) }
      let(:person) { general_agency_staff_role.person }
      let(:user) { FactoryBot.create(:user, :general_agency_staff, person: person) }

      it "should redirect" do
        expect(ga_controller).to receive(:redirect_to_show)
        subject.authorize_new(ga_controller)
      end
    end
  end

  context "authorize assign" do
    context "for an admin user" do
      let(:user) { FactoryBot.create(:user, person: person) }
      let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }

      it "should authorize" do
        expect(subject.authorize_assign(broker_controller, broker_agency_profile)).to be_truthy
      end
    end

    context "for a broker_role" do
      let(:person) { FactoryBot.create(:person) }
      let(:user) { FactoryBot.create(:user, :broker, person: person) }

      it "should authorize" do
        expect(subject.authorize_assign(broker_controller, broker_agency_profile)).to be_truthy
      end
    end

    context "for a normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "should be redirect" do
        expect(broker_controller).to receive(:redirect_to_show)
        subject.authorize_set_default_ga(broker_controller, broker_agency_profile)
      end
    end
  end

  context "authorize set_default_ga" do
    context "for an admin user" do
      let(:user) { FactoryBot.create(:user, person: person) }
      let(:person) { FactoryBot.create(:person, :with_hbx_staff_role) }

      it "should authorize" do
        expect(subject.authorize_set_default_ga(broker_controller, broker_agency_profile)).to be_truthy
      end
    end

    context "for a broker_role" do
      let(:person) { FactoryBot.create(:person) }
      let(:user) { FactoryBot.create(:user, :broker, person: person) }

      it "should authorize" do
        expect(subject.authorize_set_default_ga(broker_controller, broker_agency_profile)).to be_truthy
      end
    end

    context "for a normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "should be redirect" do
        expect(broker_controller).to receive(:redirect_to_show)
        subject.authorize_set_default_ga(broker_controller, broker_agency_profile)
      end
    end
  end
end
