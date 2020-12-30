# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'expire_prior_year_ivl_active_enrollments')

describe ExpirePriorYearIvlActiveEnrollments, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let(:given_task_name) { 'expire_prior_year_ivl_active_enrollments' }
  subject { ExpirePriorYearIvlActiveEnrollments.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'expire ivl enrollment of prior plan year' do
    let!(:person) { FactoryBot.create(:person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        kind: 'individual',
                        aasm_state: 'unverified',
                        effective_on: TimeKeeper.date_of_record.beginning_of_year - 100.days)
    end

    after :each do
      FileUtils.rm_rf("#{Rails.root}/expired_active_enrollments_in_prior_years.csv")
    end

    context 'effective_on is in the prior year' do
      before :each do
        subject.migrate
        hbx_enrollment.reload
        @file_content = CSV.read("#{Rails.root}/expired_active_enrollments_in_prior_years.csv")
      end

      it 'should add data to the file' do
        expect(@file_content.size).to be > 1
      end

      it 'should match with the person hbx_id' do
        expect(@file_content[1][2]).to eq(person.hbx_id)
      end

      it 'should match with the enrollment hbx_id' do
        expect(@file_content[1][5]).to eq(hbx_enrollment.hbx_id)
      end

      it 'should match with the enrollment new aasm state' do
        expect(@file_content[1][6]).to eq(hbx_enrollment.aasm_state)
      end

      it 'should expire enrollment' do
        expect(hbx_enrollment.coverage_expired?).to be_truthy
      end
    end

    context 'effective_on is in the current year' do
      before :each do
        hbx_enrollment.update_attributes!(effective_on: TimeKeeper.date_of_record.beginning_of_year)
        subject.migrate
        @file_content = CSV.read("#{Rails.root}/expired_active_enrollments_in_prior_years.csv")
      end

      it 'should not add any additional data to the file' do
        expect(@file_content.size).not_to be > 1
      end

      it 'should not expire enrollment' do
        expect(hbx_enrollment.coverage_expired?).to be_falsy
      end
    end
  end
end
