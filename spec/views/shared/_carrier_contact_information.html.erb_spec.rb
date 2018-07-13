require 'rails_helper'
describe "shared/_carrier_contact_information.html.erb" do
  let(:plan) {
    double('Product',
      id: "122455",
      kind: "health",
      issuer_profile: issuer_profile
      )
  }

  let(:issuer_profile){
    double("IssuerProfile",
      legal_name: "BMC HealthNet Plan"
      )
  }
  before :each do
    render partial: "shared/carrier_contact_information", locals: { plan: plan }
  end
  it "should display the carrier name and number" do
    expect(rendered).to match issuer_profile.legal_name
    expect(rendered).to match("1-855-833-8120")
  end
end
