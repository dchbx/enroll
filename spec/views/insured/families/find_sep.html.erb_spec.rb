require 'rails_helper'

RSpec.describe "insured/families/find_sep.html.erb", :dbclean => :around_each do
  let(:current_user) {FactoryGirl.create(:user)}

  before do
    qle1 = FactoryGirl.create(:qualifying_life_event_kind, market_kind: 'individual')
    qle2 = FactoryGirl.create(:qualifying_life_event_kind, market_kind: 'individual', title: 'I had a baby')
    sign_in current_user
    assign :qualifying_life_events, [qle1, qle2]
    assign :next_ivl_open_enrollment_date, TimeKeeper.date_of_record
    assign(:person, FactoryGirl.create(:person))
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
    render
  end

  it "should have carousel with qle events for individual market" do
    expect(rendered).to have_selector('div#carousel-qles')
    QualifyingLifeEventKind.individual_market_events.each do |qle|
      expect(rendered).to have_selector( "a", text: qle.title)
    end
  end

  it "should have checkbox to skip SEP" do
    expect(rendered).to have_selector('input#no_qle_checkbox')
    expect(rendered).to have_selector("input[type='checkbox']", count: 1)
    expect(rendered).to have_link('CONTINUE', href: '/families/home')
  end

  it "should have rail road with sepcial enrollment period" do
    expect(rendered).to have_selector('div.right-section')
    expect(rendered).to have_css("li.active", text: 'Special Enrollment Period')
  end

  it "should have qle form" do
    expect(rendered).to have_selector('form#qle_form')
    expect(rendered).to have_selector('h3.qle-details-title')
    expect(rendered).to have_selector('h5.qle-label')
    expect(rendered).to have_selector("input[name='qle_date']", count: 1)
  end

  it "should have outside open enrollment modal" do
    expect(rendered).to have_selector('div.modal#outside-open-enrollment')
    expect(rendered).to match /Open enrollment starts on/
    expect(rendered).to match /To enroll before open enrollment, you must qualify for a special enrollment period. If none of the circumstances listed apply to you, you will not be able to enroll until/
    expect(rendered).to have_selector("a[href='/families/home']", text: 'Back To My Account')
  end
end
