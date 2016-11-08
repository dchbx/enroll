require 'rails_helper'

RSpec.describe "insured/families/_qles_panel.html.erb" do
  context 'update authorized' do
  before :each do

    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))

    10.times.each {FactoryGirl.create(:qualifying_life_event_kind)}
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    assign(:person, FactoryGirl.create(:person))
    render "insured/families/qles_panel"
  end

    it "should display the title" do
      expect(rendered).to have_selector('h4', text: 'Have life changes?')
      expect(rendered).to have_selector('small', text: 'See how it may affect your health insurance.')
      expect(rendered).to have_selector('h5', text: 'TOP LIFE CHANGES')
    end

    it "should have carousel" do
      expect(rendered).to have_selector('div#carousel-qles')
      expect(rendered).to have_selector('div.carousel-inner')
      expect(rendered).to have_selector('ol.carousel-indicators')
      expect(rendered).to have_selector('a.carousel-control', count: 2)
    end

    it "should have qle options" do
      QualifyingLifeEventKind.all.each do |qle|
        expect(rendered).to have_selector('a.qle-menu-item', text: qle.title)
      end
    end

    it "should have image" do
      expect(rendered).to have_selector('img[alt="Life event"]')
    end

    it "should not have links blocked" do
      expect(rendered).not_to have_selector('.blocking')
    end
  end
 
  context 'update not authorized' do
    before :each do

     allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: false))

    10.times.each {FactoryGirl.create(:qualifying_life_event_kind)}
    assign(:qualifying_life_events, QualifyingLifeEventKind.all)
    assign(:person, FactoryGirl.create(:person))
    render "insured/families/qles_panel"
  end

    it "should have links blocked" do
        expect(rendered).to have_selector('.blocking')
    end
  end
end
