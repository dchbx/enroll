require 'rails_helper'

RSpec.describe "insured/families/_effective_on_kind_fields.html.erb" do
  let(:qlk) {FactoryGirl.create(:qualifying_life_event_kind)}
  let(:person) {FactoryGirl.create(:person)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}

  before :each do
    assign :qle, qlk
    assign :qle_date, TimeKeeper.date_of_record
    assign :person, person
    allow(person).to receive(:primary_family).and_return(family)
    allow(family).to receive(:special_enrollment_periods).and_return([])
  end

  it "should show hidden field" do
    allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event'])
    render "insured/families/effective_on_kind_fields"
    expect(rendered).to have_selector('input#effective_on_kind')
  end

  it "should have select for effective_on_kind" do
    allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event', "first_of_next_month"])
    render "insured/families/effective_on_kind_fields"
    expect(rendered).to have_selector('select#effective_on_kind')
  end

  context "when Had a baby" do
    before :each do
      assign :qle_date, TimeKeeper.date_of_record
      allow(qlk).to receive(:reason).and_return("birth")
      allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event', 'fixed_first_of_next_month'])
      render "insured/families/effective_on_kind_fields"
    end

    it "should have effective_on_kind options with date" do

      expect(rendered).to have_selector("option", text: "#{TimeKeeper.date_of_record.to_s}")
      expect(rendered).to have_selector("option", text: "#{(TimeKeeper.date_of_record.end_of_month + 1.day).to_s}")
    end

    it "should have qle_effective_on_kind_alert area" do
      expect(rendered).to match /Please Select effective date/i
    end
  end

  context "when Adopted a child" do
    before :each do
      assign :qle_date, TimeKeeper.date_of_record
      allow(qlk).to receive(:reason).and_return("adoption")
      allow(qlk).to receive(:effective_on_kinds).and_return(['date_of_event', 'fixed_first_of_next_month'])
      render "insured/families/effective_on_kind_fields"
    end

    it "should have effective_on_kind options with date" do
      expect(rendered).to have_selector("option", text: "#{TimeKeeper.date_of_record.to_s}")
      expect(rendered).to have_selector("option", text: "#{(TimeKeeper.date_of_record.end_of_month + 1.day).to_s}")
    end

    it "should have qle_effective_on_kind_alert area" do
      expect(rendered).to match /Please Select effective date/i
    end
  end
end
