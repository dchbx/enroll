# frozen_string_literal: true

require 'rails_helper'

describe IvlEnrollmentEligibilityReport, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Time.zone.today)
  end

  let(:given_task_name) { 'ivl_eligibility_report' }
  subject { IvlEnrollmentEligibilityReport.new(given_task_name, double(:current_scope => nil)) }

  context 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  context 'with date as first of the month' do
    let!(:person) { FactoryBot.create(:person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_health_product,
                        family: family, enrollment_members: [family.primary_applicant],
                        aasm_state: 'coverage_selected', kind: 'individual')
    end

    before do
      current_date = TimeKeeper.date_of_record
      year = current_date.year
      month = current_date.month
      TimeKeeper.set_date_of_record_unprotected!(Date.new(year,month,1))
    end

    context 'person with valid DC Address' do
      before do
        subject.migrate
        @file_content = CSV.read("#{Rails.root}/list_of_ivl_enrolled_members_1.csv")
      end

      it 'should add data to the file' do
        expect(@file_content.size).to be > 1
      end

      it 'should match with the person hbx_id' do
        expect(@file_content[1][0]).to eq(person.hbx_id)
      end

      it 'should match with the First_Name' do
        expect(@file_content[1][2]).to eq(person.first_name)
      end

      it 'should match with the Last_Name' do
        expect(@file_content[1][3]).to eq(person.last_name)
      end

      it 'should match with the Residency Status' do
        expect(@file_content[1][5]).to eq('YES')
      end

      it 'should match with the Incarcerated Status' do
        expect(@file_content[1][7]).to eq('NO')
      end
    end

    context 'person with NO DC Address' do
      before do
        person.update_attributes!(no_dc_address: true, no_dc_address_reason: '')
        subject.migrate
        @file_content = CSV.read("#{Rails.root}/list_of_ivl_enrolled_members_1.csv")
      end

      it 'should match with the Residency Status' do
        expect(@file_content[1][5]).to eq('NO')
      end

      it 'should match with the Incarcerated Status' do
        expect(@file_content[1][7]).to eq('NO')
      end
    end

    context 'person with NO DC Address and no_dc_address_reason' do
      before do
        person.update_attributes!(no_dc_address: true, no_dc_address_reason: 'Test DC Address Reason')
        subject.migrate
        @file_content = CSV.read("#{Rails.root}/list_of_ivl_enrolled_members_1.csv")
      end

      it 'should match with the Residency Status' do
        expect(@file_content[1][5]).to eq('YES')
      end

      it 'should match with the Incarcerated Status' do
        expect(@file_content[1][7]).to eq('NO')
      end
    end

    context 'person with incarcerated status' do
      before do
        person.update_attributes!(is_incarcerated: true)
        subject.migrate
        @file_content = CSV.read("#{Rails.root}/list_of_ivl_enrolled_members_1.csv")
      end

      it 'should match with the Incarcerated Status' do
        expect(@file_content[1][7]).to eq('YES')
      end
    end
  end

  context 'with date as not first of the month' do
    before do
      current_date = TimeKeeper.date_of_record
      year = current_date.year
      month = current_date.month
      TimeKeeper.set_date_of_record_unprotected!(Date.new(year,month,2))
      subject.migrate
    end

    it 'should not create any output csv' do
      expect{CSV.read("#{Rails.root}/list_of_ivl_enrolled_members_1.csv")}.to raise_error(Errno::ENOENT)
    end
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/list_of_ivl_enrolled_members_1.csv")
  end
end
