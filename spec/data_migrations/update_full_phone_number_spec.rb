require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_full_phone_number")

describe UpdateFullPhoneNumber do

  describe "given a task name" do
    let(:given_task_name) { "migrate_update_full_phone_number" }
    subject { UpdateFullPhoneNumber.new(given_task_name, double(:current_scope => nil)) }

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "migrating full phone number of person when nil" do
    subject { UpdateFullPhoneNumber.new("fix me task", double(:current_scope => nil)) }

    context "get person phones " do
      let(:person) { FactoryGirl.create(:person) }
      let(:params) { {kind: "home", person: person} }
      let(:phone) { Phone.create(**params) }
      before :each do
        phone.number ="1234567"
        phone.area_code = "987"
        phone.extension = "456"
        phone.save!
        subject.migrate
        phone.reload
      end
      it "full phone number is set with combination of number,extension,area code " do
        expect(phone.full_phone_number).to eq "9871234567456"
      end
    end
  end

  describe "migrating full phone number of office location when nil" do
    subject { UpdateFullPhoneNumber.new("fix me task", double(:current_scope => nil)) }

    context "get office phones" do
      let(:organization) { FactoryGirl.create(:organization) }
      let(:phone) { FactoryGirl.build(:phone) }
      let(:valid_params) { {
          organization: organization,
          phone: phone
      } }
      let(:office_location) { [OfficeLocation.create(**valid_params)] }
      before :each do
        organization.office_locations.first.phone.number ="2222222"
        organization.office_locations.first.phone.area_code = "456"
        organization.office_locations.first.phone.extension = "908"
        organization.office_locations.first.phone.save!
        subject.migrate
        organization.office_locations.first.phone.reload
      end

      it "full phone number is set with combination of number,extension,area code" do
        expect(organization.office_locations.first.phone.full_phone_number).to eq "4562222222908"
      end
    end
  end
end
