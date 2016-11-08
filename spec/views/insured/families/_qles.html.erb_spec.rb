require 'rails_helper'

RSpec.describe "insured/families/_qles.html.erb" do
  before :each do
    QualifyingLifeEventKind.delete_all
    10.times.each {FactoryGirl.create(:qualifying_life_event_kind)}
    FactoryGirl.create(:qualifying_life_event_kind, tool_tip: "")
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
    render "insured/families/qles"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h4', text: 'TOP LIFE CHANGES')
  end

  it "should have list-qle area" do
    expect(rendered).to have_selector('ul.list-qle')
  end

  it "should have qle options" do
    QualifyingLifeEventKind.all.each do |qle|
      expect(rendered).to have_selector('a.qle-menu-item', text: qle.title.humanize)
    end
  end

  it "should have qle-details" do
    expect(rendered).to have_selector('div#qle-details.hidden')
  end

  it "should have placement bottom options" do
    expect(rendered).to have_selector("a.qle-menu-item[data-placement='bottom']")
    expect(rendered).to have_selector("a.qle-menu-item[data-placement='top']")
  end

  it "should not have tooltip when tool_tip is blank" do
    expect(rendered).to have_selector("a.qle-menu-item[data-toggle='tooltip']", count: 10)
    expect(rendered).to have_selector("a.qle-menu-item", count: 11)
    expect(rendered).to have_selector("a[data-is-self-attested='true']")
  end
end
