require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe "_waived_coverage_widget.html.erb",  dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  
  let(:person) {FactoryBot.create(:person)}
  let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let(:family_members){ family.family_members.where(is_primary_applicant: false).to_a }
  let(:household){ family.active_household }
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                           household: household,
                                           family: family,
                                           hbx_enrollment_members: [hbx_enrollment_member],
                                           coverage_kind: "health",
                                           external_enrollment: false,
                                           sponsored_benefit_id: sponsored_benefit.id,
                                           rating_area_id: rating_area.id)
  }
  let(:benefit_group) { current_benefit_package }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package ) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let!(:sponsored_benefit) { initial_application.benefit_packages.first.sponsored_benefits.first }

  before :each do
    assign(:person, person)
    allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
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
      expect(rendered).to match(abc_profile.legal_name)
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
