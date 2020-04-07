require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesHelper, dbclean: :after_each, :type => :helper do

  let(:user) { FactoryBot.create(:user) }
  let(:person) { FactoryBot.create(:person, user: user) }
  let(:person2) { FactoryBot.create(:person) }

  describe 'disable_edit_broker_agency?' do
    it 'should return false if current user has broker role' do
      allow(person).to receive(:broker_role).and_return true
      expect(helper.disable_edit_broker_agency?(user)).to be_falsey
    end

    it 'should return true if current user does not have broker role' do
      allow(person).to receive(:broker_role).and_return false
      expect(helper.disable_edit_broker_agency?(user)). to eq true
    end

    it 'should return true if current user has staff role' do
      allow(user).to receive(:has_hbx_staff_role?).and_return true
      expect(helper.disable_edit_broker_agency?(user)).to be_falsey
    end
  end

  describe 'can_show_destroy_for_brokers?' do
    context "total broker staff count" do
      it "should return false if single staff member remains" do
        expect(helper.can_show_destroy_for_brokers?(person, 1)).to be_falsey
      end
    end

    context "with broker role" do
      it 'should return true if current user is logged in' do
        allow(person).to receive(:broker_role).and_return true
        expect(helper.can_show_destroy_for_brokers?(person, 2)). to be_falsey
      end

      it 'should return false if staff has broker role' do
        allow(person).to receive(:broker_role).and_return true
        expect(helper.can_show_destroy_for_brokers?(person, 2)). to be_falsey
      end

      it 'should return true if staff DOES NOT HAVE broker role' do
        allow(person).to receive(:broker_role).and_return false
        expect(helper.can_show_destroy_for_brokers?(person2, 2)).to be_truthy
      end
    end
  end

  describe 'can_show_destroy_for_ga?' do
    context "total general agency staff count" do
      it "should return false if single staff member remains" do
        expect(helper.can_show_destroy_for_ga?(person, 1)).to be_falsey
      end
    end

    context "with general agency staff" do
      it 'should return false if staff has primary ga staff role' do
        allow(person).to receive(:general_agency_primary_staff).and_return true
        expect(helper.can_show_destroy_for_ga?(person, 2)).to be_falsey
      end

      it 'should return true if staff DOES NOT HAVE has primary ga staff role' do
        allow(person).to receive(:general_agency_primary_staff).and_return false
        expect(helper.can_show_destroy_for_ga?(person2, 2)).to be_truthy
      end
    end
  end
end
