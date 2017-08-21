require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_new_eligibility_determination")
describe AddNewEligibilityDetermination, dbclean: :after_each do
  let(:given_task_name) { "add_new_eligibility_determination" }
  subject { AddNewEligibilityDetermination.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "add a new eligibility determination to the person" do
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member)}
    let!(:tax_household){FactoryGirl.create(:tax_household, household:family.active_household)}
    let!(:eligibility_determinations){FactoryGirl.create(:eligibility_determination, tax_household:tax_household)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(family.person.hbx_id)
    end
    context "add a new eligibility determination to the person" do
      before do
        allow(ENV).to receive(:[]).with("effective_date").and_return TimeKeeper.datetime_of_record+1.day
        allow(ENV).to receive(:[]).with("csr_percent_as_integer").and_return 50
        allow(ENV).to receive(:[]).with("max_aptc").and_return 200
      end
      context "add new eligibility determination to the person"
      it "should change person' csr" do
        ed=eligibility_determinations
        th=tax_household
        expect(th.latest_eligibility_determination.csr_percent_as_integer).to eq ed.csr_percent_as_integer
        expect(th.latest_eligibility_determination.csr_percent).to eq ed.csr_percent
        subject.migrate
        family.reload
        th.reload
        expect(th.latest_eligibility_determination.csr_percent_as_integer).to eq 50
        expect(th.latest_eligibility_determination.csr_percent).to eq 0.5
      end
    end
    context "change person's aptc" do
      before do
        allow(ENV).to receive(:[]).with("effective_date").and_return TimeKeeper.datetime_of_record+1.day
        allow(ENV).to receive(:[]).with("csr_percent_as_integer").and_return 50
        allow(ENV).to receive(:[]).with("max_aptc").and_return 200
      end
      context "change person's csr"
      it "should change person' csr" do
        ed=eligibility_determinations
        th=tax_household
        expect(th.latest_eligibility_determination.max_aptc).to eq ed.max_aptc
        subject.migrate
        family.reload
        th.reload
        expect(th.latest_eligibility_determination.max_aptc).to eq 200
      end
    end
  end
end