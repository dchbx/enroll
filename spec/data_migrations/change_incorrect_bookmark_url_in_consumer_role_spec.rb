require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_incorrect_bookmark_url_in_consumer_role")
describe ChangeIncorrectBookmarkUrlInConsumerRole do

    let(:given_task_name) { "change_incorrect_bookmark_url_in_consumer_role" }
    subject { ChangeIncorrectBookmarkUrlInConsumerRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the incorrect bookmark url for a consumer role" do
    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_family) }
    let(:household) { FactoryGirl.create(:household, family: person.primary_family) }
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: person.primary_family.latest_household, kind: "individual")}
    before(:each) do
      allow(household).to receive(:hbx_enrollments).with(:first).and_return enrollment
    end

    it "should not change the bookmark_url if they not passed RIDP" do
      person.user = FactoryGirl.create(:user, :consumer)
      person.user.update_attributes(:idp_verified => false)
      person.consumer_role.update_attribute(:bookmark_url, "/insured/family_members?consumer_role_id")
      subject.migrate
      person.reload
      expect(person.consumer_role.bookmark_url).to eq "/insured/family_members?consumer_role_id"
    end
    
    it "should not change the bookmark_url if they don't have addresses" do
      person.user = FactoryGirl.create(:user, :consumer)
      person.user.update_attributes(:idp_verified => true)
      person.user.ridp_by_payload!
      person.addresses.to_a.each do |add|
        add.delete
      end
      person.consumer_role.update_attribute(:bookmark_url, "/insured/family_members?consumer_role_id")
      subject.migrate
      person.reload
      expect(person.consumer_role.bookmark_url).to eq "/insured/family_members?consumer_role_id"
    end

    it "should change the bookmark_url if it has addresses, active enrollment and passed RIDP" do
      person.user = FactoryGirl.create(:user, :consumer)
      person.user.update_attribute(:idp_verified, true)
      person.user.ridp_by_payload!
      person.consumer_role.update_attribute(:bookmark_url, "/insured/family_members?consumer_role_id")
      subject.migrate
      person.reload
      expect(person.consumer_role.bookmark_url).to eq "/families/home"
    end
  end
end
