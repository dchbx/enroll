require 'rails_helper'

describe "employers/census_employees/_enrollment_details.html.erb", dbclean: :after_each do

  let(:person) {FactoryBot.create(:person)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:active_household) {family.active_household}
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true, applicant_id: family.family_members.first.id, coverage_start_on: TimeKeeper.date_of_record, eligibility_date: TimeKeeper.date_of_record) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: active_household, hbx_enrollment_members:[hbx_enrollment_member])}
  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id,product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
  let(:decorated_hbx_enrollment) {double(member_enrollments:[member_enrollment], product_cost_total:'',sponsor_contribution_total:'')}

  before :each do
    allow(enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
  end

  it "when enrollment is single plan sponosored benefit should return dash for premium & employer contribution" do
    allow(enrollment).to receive(:composite_rated?).and_return(true)
    render "employers/census_employees/enrollment_details", enrollment: enrollment
    expect(rendered).to have_selector('td', text: "--")
  end

  it "when enrollment is not a single plan sponosored benefit should return amount for premium & employer contribution" do
    allow(enrollment).to receive(:composite_rated?).and_return(false)
    render "employers/census_employees/enrollment_details", enrollment: enrollment
    expect(rendered).to have_selector('td', text: 100)
  end
end
