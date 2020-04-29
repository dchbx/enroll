require "rails_helper"

describe ExternalApplications::ApplicationProfile do
  it "can't find an arbitrary application" do
    expect(ExternalApplications::ApplicationProfile.find_by_application_name("a., jasdklfal")).to be_nil
  end

  it "can find the admin application" do
    expect(ExternalApplications::ApplicationProfile.find_by_application_name("admin")).not_to be_nil
  end

  it "has the right policy for the admin application" do
    profile = ExternalApplications::ApplicationProfile.find_by_application_name("admin")
    expect(profile.policy_class).to eq AngularAdminApplicationPolicy
  end

  it "has the list of applications" do
    expect(ExternalApplications::ApplicationProfile.load_external_applications.length > 0).to be_truthy
  end
end