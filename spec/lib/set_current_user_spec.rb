require 'rails_helper'

describe SetCurrentUser do
  let(:user) { FactoryBot.create(:user) }

  before do
    extend SetCurrentUser
  end

  context "with module on top level model" do
    let(:org) { FactoryBot.build(:organization) }

    before(:each) do
      SAVEUSER[:current_user_id] = user.id
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    it "updates the user when it is saved" do
      expect(org.updated_by_id).to eq nil
      org.save
      expect(org.updated_by_id).to eq user.id
    end

    it "updates user when it is updated" do
      org.update_attribute(:legal_name, "something new")
      expect(org.updated_by_id).to eq user.id
    end

    context "a different user makes an update to top level object" do
      let(:user1) { FactoryBot.create(:user) }

      it "updates user" do
        SAVEUSER[:current_user_id] = user1.id
        org.update_attribute(:legal_name, "something else")
        expect(org.updated_by_id).to eq user1.id
      end
    end

    context "a different user makes an update to an embedded object" do
      let(:user2) { FactoryBot.create(:user) }

      it "does not update the user" do
        SAVEUSER[:current_user_id] = user2.id
        org.office_locations.first.address.update_attribute(:address_1, "some new place NE")
        expect(org.updated_by_id).to eq user2.id
      end
    end
  end
end
