require "rails_helper"

describe "Eligilibity Audit" do
  let(:organization) { FactoryBot.create :organization }
  let!(:hbx_profile) do
    FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period, organization: organization)
  end
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, :with_family_members, person: non_curam_ivl_person) }
  let(:non_curam_ivl_person) do
    FactoryBot.create(:person, :with_family, first_name: "Tom", last_name: "Cruise", created_at: audit_end_date - 1.week)
  end
  let(:consumer_role) do
    ConsumerRole.create!(
      person: non_curam_ivl_person,
      is_state_resident: 'yes',
      citizen_status: 'us_citizen',
      vlp_documents: [FactoryBot.build(:vlp_document)],
      ridp_documents: [FactoryBot.build(:ridp_document)],
      is_applicant: true
    )
  end
  let(:audit_start_date) { Date.new(2018,10,1) }
  let(:audit_end_date) { Date.new(2019,10,1) }

  context "person with multiple history records" do
    before do
      non_curam_ivl_person
      consumer_role
      allow(non_curam_ivl_person).to receive(:consumer_role).and_return(consumer_role)
      allow_any_instance_of(Person).to receive(:updated_at).and_return((audit_end_date - 1.week).to_datetime)
      # Assure existence of history tracks
      non_curam_ivl_person.update_attributes!(addresses_attributes: { "0" => { id: non_curam_ivl_person.addresses.first.id, address_1: '111 1 St NE' } })
      allow_any_instance_of(HistoryTracker).to receive(:created_at).and_return((audit_start_date + 1.week).to_datetime)
      expect(non_curam_ivl_person.history_tracks.length).to be > 1
      eligibility_audit = File.join(Rails.root, "script/eligibility_audit.rb")
      load eligibility_audit
      @file = "#{Rails.root}/audit_ivl_determinations.csv"
    end

    it "creates csv file with expected attributes including for person history tracks" do
      file_context = CSV.read(@file)
      expect(file_context.size).to be > 2
      row_with_data = file_context[1]
      person_csv_row = [
        non_curam_ivl_person.hbx_id,
        non_curam_ivl_person.last_name,
        non_curam_ivl_person.first_name,
        non_curam_ivl_person.full_name,
        non_curam_ivl_person.gender
      ]
      person_csv_row.each do |person_attribute|
        expect(row_with_data).to include(person_attribute)
      end
    end
  end

  context "person with zero versions and history records" do
    before do
      Person.delete_all
      non_curam_ivl_person
      consumer_role
      allow(non_curam_ivl_person).to receive(:consumer_role).and_return(consumer_role)
      allow_any_instance_of(Person).to receive(:updated_at).and_return(audit_end_date - 1.week)
      # Assure existence of history tracks
      non_curam_ivl_person.history_tracks.destroy_all
      expect(non_curam_ivl_person.history_tracks.length).to eq(0)
      eligibility_audit = File.join(Rails.root, "script/eligibility_audit.rb")
      load eligibility_audit
      @file = "#{Rails.root}/audit_ivl_determinations.csv"
    end

    it "creates csv file for person" do
      file_context = CSV.read(@file)
      expect(file_context.size).to eq(2)
      row_with_data = file_context[1]
      person_csv_row = [
        non_curam_ivl_person.hbx_id,
        non_curam_ivl_person.last_name,
        non_curam_ivl_person.first_name,
        non_curam_ivl_person.full_name,
        non_curam_ivl_person.gender
      ]
      person_csv_row.each do |person_attribute|
        expect(row_with_data).to include(person_attribute)
      end
    end
  end
end
