require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "eligibility_determination_determined_on_migration")

describe EligibilityDeterminationDeterminedOnMigration, dbclean: :after_each do

  let(:given_task_name) { "migrate_deprecated_eligibility_determination_field" }
  subject { EligibilityDeterminationDeterminedOnMigration.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Eligibility Determination Determinted On Migration", dbclean: :after_each do

    let!(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let!(:household) { FactoryBot.create(:household, family: family) }
    let!(:tax_household) { FactoryBot.create(:tax_household, household: household, submitted_at: determined_at_initial_value) }
    let!(:eligibility_determination) do
      FactoryBot.create(
        :eligibility_determination,
        tax_household: tax_household,
      )
    end
    let(:determined_at_initial_value) { DateTime.new(2015,2,3,4,5,6) }

    before :each do
      eligibility_determination.update_attributes!(determined_at: determined_at_initial_value)
    end
    
    it "should create a CSV with eligibility determination fields" do
      expect(eligibility_determination.determined_at).to_not eq(eligibility_determination.determined_on)
      expect(eligibility_determination.determined_at).to eq(determined_at_initial_value)
      subject.migrate
      eligibility_determination.reload
      filename = "#{Rails.root}//eligibility_determination_migration_report.csv"
      expect(File.exists?(filename)).to eq(true)
      csv = CSV.read(filename)
      expect(csv[1][0]).to eq(family.person.hbx_id.to_s)
      expect(csv[1][1]).to eq(eligibility_determination._id.to_s)
      # Changes the determine on to determined at
      expect(eligibility_determination.determined_at).to eq(eligibility_determination.determined_on)
    end

    it "should migrate EligibilityDetermination determined_on field to determined_at" do
      expect(eligibility_determination.determined_at).to_not eq(eligibility_determination.determined_on)
      expect(eligibility_determination.determined_at).to eq(determined_at_initial_value)
      subject.migrate
      eligibility_determination.reload
      # Changes the determine on to determined at
      expect(eligibility_determination.determined_at).to eq(eligibility_determination.determined_on)
    end
  end
end
