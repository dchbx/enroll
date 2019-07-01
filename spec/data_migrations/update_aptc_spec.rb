require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  require File.join(Rails.root, "app", "data_migrations", "update_aptc")

  describe UpdateAptc, dbclean: :after_each do
    let(:given_task_name) { "update_aptc" }
    subject { UpdateAptc.new(given_task_name, double(:current_scope => nil)) }

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    describe "updating the applied aptc amount for hbx_enrollments" do
      let(:person) { FactoryBot.create(:person, :with_family) }
      let(:family) { person.primary_family }
      let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, elected_amount: 100.00, household: family.active_household, :coverage_kind => "health", applied_aptc_amount: 0)}
      let!(:hbx_enrollment1) {FactoryBot.create(:hbx_enrollment, family: family, :coverage_kind => "dental", household: family.active_household, elected_amount: 300, applied_aptc_amount: 10.00)}

      it "should update aptc amount" do
        expect(family.active_household.hbx_enrollments).to include hbx_enrollment
        expect(hbx_enrollment.applied_aptc_amount.to_f).to eq 0.00
        expect(hbx_enrollment1.applied_aptc_amount.to_f).to eq 10.00
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment.applied_aptc_amount.to_f).to eq 100.00
        hbx_enrollment1.reload
        expect(hbx_enrollment1.applied_aptc_amount.to_f).to eq 10.00
      end
    end
  end
end