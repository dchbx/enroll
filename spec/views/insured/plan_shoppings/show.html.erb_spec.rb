require "rails_helper"

=begin
RSpec.describe "insured/show" do
  let(:employee_role){FactoryGirl.create(:employee_role)}
  let(:plan){FactoryGirl.create(:plan)}
  let(:benefit_group){ FactoryGirl.build(:benefit_group) }
  let(:hbx_enrollment_member_one) { FactoryGirl.build_stubbed(:hbx_enrollment_member, is_subscriber: false) }
  let(:family) { FactoryGirl.build_stubbed(:family, person: person, family_members: [hbx_enrollment_member_one]) }
  let(:hbx_enrollment){ HbxEnrollment.new(benefit_group: benefit_group,
    hbx_enrollment_members: [hbx_enrollment_member_one],
    employee_role: employee_role,
    effective_on: 1.month.ago.to_date, updated_at: DateTime.now  ) }
  let(:broker_agency_profile){FactoryGirl.create(:broker_agency_profile)}
  let(:broker_role){FactoryGirl.build(:broker_role, broker_agency_profile_id: broker_agency_profile.id)}
  let(:broker_person){ FactoryGirl.create(:person, :first_name=>'fred', :last_name=>'flintstone')}
  let(:person) {FactoryGirl.create(:person, :first_name=> 'wilma', :last_name=>'flintstone')}
  let(:consumer_role) {FactoryGirl.create(:consumer_role, person: person)}
  let(:current_broker_user) { FactoryGirl.create(:user, :roles => ['broker_agency_staff'],
 		:person => broker_person) }
  let(:consumer_user){FactoryGirl.create(:user, :roles => ['consumer'], :person => person)}

  before :each do
    allow(hbx_enrollment_member_one).to receive(:person).and_return(person)
    allow(hbx_enrollment).to receive(:humanized_dependent_summary).and_return(2)
    allow(hbx_enrollment).to receive_message_chain("household.family").and_return(family)
    @person = person
    @hbx_enrollment = hbx_enrollment
    @benefit_group = benefit_group
    @reference_plan = @benefit_group.reference_plan
    @plan = PlanCostDecorator.new(plan, hbx_enrollment, @benefit_group, @reference_plan)
    @plans=[]
    assign(:market_kind, "shop")
    assign(:coverage_kind, "health")
    stub_template "insured/plan_shoppings/_plan_details.html.erb" => []
    stub_template "shared/_signup_progress.html.erb" => ''
    stub_template "insured/_plan_filters.html.erb" => ''
    current_broker_user.person.broker_role = BrokerRole.new({:broker_agency_profile_id => 99})
  end

  it 'should display information about the employee when signed in as Broker' do
    sign_in current_broker_user
    render :template => "insured/plan_shoppings/show.html.slim"
    expect(rendered).to have_selector('span', text:  @person.full_name)
    expect(rendered).to match(@benefit_group.plan_year.employer_profile.legal_name)
  end

  it 'should be identify Broker control in the header when signed in as Broker' do
    broker_person.broker_role = broker_role
    broker_person.save
    sign_in current_broker_user
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/I'm a Broker/)
    expect(rendered).to_not match(/Welcome|Family/)
  end

  it 'should display information about the employee when signed in as Consumer' do
    sign_in consumer_user
    render :template => "insured/plan_shoppings/show.html.slim"
    expect(rendered).to have_selector('span', text:  @person.full_name)
    expect(rendered).to match(@benefit_group.plan_year.employer_profile.legal_name)

  end

  it 'should not identify Broker control in the header when signed in as Consumer' do
    FactoryGirl.create(:consumer_role, person: consumer_user.person)
    allow(consumer_user).to receive(:identity_verified_date).and_return(true)
    sign_in consumer_user
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to_not match(/I'm a Broker/)
    expect(rendered).to match(/Individual and Family/i)
  end

  it "should get the plans-count" do
    sign_in consumer_user
    render :template => "insured/plan_shoppings/show.html.slim"
    expect(rendered).to have_selector('strong#plans-count')
  end

  it "should display special note related to plan cost" do
    sign_in consumer_user
    allow(benefit_group).to receive(:sole_source?).and_return(true)
    render :template => "insured/plan_shoppings/show.html.slim"
    expect(rendered).to match(/Please note your final cost may change based on the final enrollment of all employees./)
  end

  it "should not display note for benefit_groups other than sole_source" do
    sign_in consumer_user
    render :template => "insured/plan_shoppings/show.html"
    expect(rendered).to_not match(/Please note your final cost may change based on the final enrollment of all employees/)
  end

  it "should not render waive_confirmation partial" do
    sign_in current_broker_user
    allow(@hbx_enrollment).to receive(:employee_role).and_return(false)
    render :template => "insured/plan_shoppings/show.html.slim"
    expect(rendered).not_to have_selector('div#waive_confirm')
    expect(response).not_to render_template(partial: "insured/plan_shoppings/waive_confirmation", locals: {enrollment: hbx_enrollment})
  end

  it 'should render waive_confirmation partial' do
    sign_in current_broker_user
    allow(@hbx_enrollment).to receive(:employee_role).and_return(double)
    render :template => "insured/plan_shoppings/show.html.slim"
    expect(response).to render_template(partial: "ui-components/v1/modals/waive_confirmation", locals: {enrollment: hbx_enrollment})
  end

  it "should have plans area" do
    sign_in current_broker_user
    allow(@hbx_enrollment).to receive(:employee_role).and_return(double)
    render :template => "insured/plan_shoppings/show.html.slim"
    expect(rendered).to have_selector('#plans', text: 'Loading...')
  end
end
=end
