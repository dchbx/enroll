require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_office_phone_number")

describe ChangeOfficePhoneNumber do

  let(:given_task_name) { "change_office_phone_number" }
  subject { ChangeOfficePhoneNumber.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing the phone number of a given organization with country code ", dbclean: :after_each do
    let(:organization) { FactoryGirl.create(:organization) }
    let(:office_location) {FactoryGirl.create(:office_location,:primary, organization:organization)}
    let(:phone) { FactoryGirl.create(:phone, kind: "work", office_location:office_location) }
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("full_phone_number").and_return("20212345678")
      allow(ENV).to receive(:[]).with("country_code").and_return("1")
    end
    it "should have the correct country code" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.country_code).to eq "1"
    end
    it "should have the correct extension" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.extension).to eq "8"
    end
    it "should have the correct country code" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.country_code).to eq "1"
    end
    it "should have the correct area code" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.area_code).to eq "202"
    end
    it "should have the correct number" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.number).to eq "1234567"
    end
  end
  describe "changing the phone number of a given office with no country code ", dbclean: :after_each do
    let(:organization) { FactoryGirl.create(:organization) }
    let(:office_location) {FactoryGirl.create(:office_location,:primary, organization:organization)}
    let(:phone) { FactoryGirl.create(:phone, kind: "work", office_location:office_location) }
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("full_phone_number").and_return("20212345678")
      allow(ENV).to receive(:[]).with("country_code").and_return("")
    end

    it "should have the correct extension" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.extension).to eq "8"
    end
    it "should have the correct country code" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.country_code).to eq ""
    end
    it "should have the correct area code" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.area_code).to eq "202"
    end
    it "should have the correct number" do
      subject.migrate
      organization.reload
      phone = organization.primary_office_location.phone
      expect(phone.number).to eq "1234567"
    end
  end
end
