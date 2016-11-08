require 'rails_helper'

RSpec.describe "_waived_coverage_widget.html.erb" do

  context 'insured home waived coverage widget' do
    let(:hbx_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household) }
    let(:household) { FactoryGirl.build_stubbed(:household, family: family) }
    let(:family) { FactoryGirl.build_stubbed(:family, person: person) }
    let(:person) { FactoryGirl.build_stubbed(:person) }
    let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }

    before :each do
      assign(:person, person)
      allow(hbx_enrollment).to receive(:employer_profile).and_return(employer_profile)
      render partial: 'insured/families/waived_coverage_widget', locals: { hbx_enrollment: hbx_enrollment, read_only: false }
    end

    it "should display coverage waived widget" do
      expect(rendered).to match (/waived/i)
    end

    it "should display coverage waived time stamp" do
      expect(rendered).to match((hbx_enrollment.submitted_at.in_time_zone('Eastern Time (US & Canada)')).strftime("%m/%d/%Y"))
      expect(rendered).to match((hbx_enrollment.submitted_at.in_time_zone('Eastern Time (US & Canada)')).strftime("%-I:%M%p"))
    end

    it "should display employer profiles legal name" do
      expect(rendered).to match(employer_profile.legal_name)
    end

  end
end
