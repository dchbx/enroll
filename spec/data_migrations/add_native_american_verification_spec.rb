require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_native_american_verification")

describe AddNativeVerification, :dbclean => :after_each do
  subject { AddNativeVerification.new("fix me task", double(:current_scope => nil)) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}

  shared_examples_for "native american verification status" do |new_status, current_status, indian|
    it "assigns #{new_status} as native_validation status" do
      person.consumer_role.update_attribute("citizen_status", indian) if indian
      person.consumer_role.update_attribute("native_validation", current_status) if current_status
      subject.migrate
      person.reload
      expect(person.consumer_role.native_validation).to eq new_status
    end
  end

  context "not curam" do
    context "non native" do
      it_behaves_like "native american verification status", "na", nil
      it_behaves_like "native american verification status", "na", "na"
      it_behaves_like "native american verification status", "na", "outstanding"
      it_behaves_like "native american verification status", "na", "pending"
      it_behaves_like "native american verification status", "na", "valid"
    end
    context "native" do
      it_behaves_like "native american verification status", "outstanding", nil, "indian_tribe_member"
      it_behaves_like "native american verification status", "pending", "pending", "indian_tribe_member"
      it_behaves_like "native american verification status", "valid", "valid", "indian_tribe_member"
      it_behaves_like "native american verification status", "outstanding", "na", "indian_tribe_member"
      it_behaves_like "native american verification status", "outstanding", "outstanding", "indian_tribe_member"
    end
  end

  context "curam" do
    before do
      person.consumer_role.lawful_presence_determination.update_attribute("vlp_authority", "curam")
    end
    context "non native" do
      it_behaves_like "native american verification status", "na", nil
      it_behaves_like "native american verification status", "na", "na"
      it_behaves_like "native american verification status", "na", "outstanding"
      it_behaves_like "native american verification status", "na", "pending"
      it_behaves_like "native american verification status", "na", "valid"
    end
    context "native" do
      it_behaves_like "native american verification status", "valid", nil, "indian_tribe_member"
      it_behaves_like "native american verification status", "valid", "pending", "indian_tribe_member"
      it_behaves_like "native american verification status", "valid", "valid", "indian_tribe_member"
      it_behaves_like "native american verification status", "valid", "na", "indian_tribe_member"
      it_behaves_like "native american verification status", "valid", "outstanding", "indian_tribe_member"
    end
  end
end