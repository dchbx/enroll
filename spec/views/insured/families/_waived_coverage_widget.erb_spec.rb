require 'rails_helper'

RSpec.describe "_waived_coverage_widget.html.erb" do

  let(:hbx_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household) }
  let(:household) { FactoryGirl.build_stubbed(:household, family: family) }
  let(:family) { FactoryGirl.build_stubbed(:family, person: person) }
  let(:person) { FactoryGirl.build_stubbed(:person) }
  let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }

  before :each do
    assign(:person, person)
    allow(hbx_enrollment).to receive(:employer_profile).and_return(employer_profile)
  end
  # Added in the case of @person not persent
  context 'a person object not passed to widget' do
    let(:person) { nil }
    
    before :each do
      render partial: 'insured/families/waived_coverage_widget', locals: { hbx_enrollment: hbx_enrollment, read_only: true }
    end
    
    it 'should not break the page' do
      expect(rendered).to match (/waived/i)
    end
  end

  context 'insured home waived coverage widget' do

    before :each do
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

    it "should display make changes button" do
      expect(rendered).to have_link('Make Changes')
    end
  end

  context "when EE is outside open enrollment" do
    before :each do
      render partial: 'insured/families/waived_coverage_widget', locals: { hbx_enrollment: hbx_enrollment, read_only: true }
    end

    it "should not display make changes button" do
      expect(rendered).not_to have_link('Make Changes')
    end
  end
end
