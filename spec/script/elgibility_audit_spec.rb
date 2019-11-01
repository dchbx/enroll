require "rails_helper"

describe "Eligilibity Audit" do
  let(:organization) { FactoryBot.create :organization }
  let!(:hbx_profile) do
    FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period, organization: organization)
  end

  before(:each) do
    eligibility_audit = File.join(Rails.root, "script/eligibility_audit.rb")
    load eligibility_audit
    @file = "#{Rails.root}/audit_ivl_determinations.csv"
  end

  it "creates csv file" do
    file_context = CSV.read(@file)
    expect(file_context.size).to be > 0
  end

  describe "#each_person_version" do
    let(:person) { FactoryBot.create :person }

    before do
      person.update_attributes addresses_attributes: { "0" => { id: person.addresses.first.id, address_1: '111 1 St NE' } }
    end

    specify { expect { |b| each_person_version(person, &b) }.to yield_control.at_least(2).times }
      #yield_successive_args(1, 2)
  end
end
