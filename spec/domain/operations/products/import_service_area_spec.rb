# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::ImportServiceArea, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'clients with geographic rating areas' do

    let(:import_timestamp) { DateTime.now }
    let(:cz_file) { 'spec/test_data/plan_data/rating_areas/county_zipcode.xlsx' }
    let(:file) { 'spec/test_data/plan_data/service_areas/service_area.xlsx' }
    let(:year) { TimeKeeper.date_of_record.year }
    let(:site) { build(:benefit_sponsors_site, :with_owner_exempt_organization) }
    let!(:issuer_profile) { create(:benefit_sponsors_organizations_issuer_profile, organization: site.owner_organization, issuer_hios_ids: ['12234']) }

    describe 'single geographic rating area' do
      let(:params) do
        {
          file: file,
          year: year,
          row_data_begin: 13
        }
      end

      before :each do
        allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(setting: double(item: 'single')))
      end

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to eq true
      end

      it 'should create one rating area for each issuer' do
        subject.call(params)
        expect(::BenefitMarkets::Locations::ServiceArea.all.count).to eq 1
      end

      it 'should not create rating area if there is an existing one' do
        FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "#{Settings.aca.state_abbreviation}S001", issuer_profile_id: issuer_profile.id, issuer_provided_title: issuer_profile.legal_name, county_zip_ids: [])
        subject.call(params)
        expect(::BenefitMarkets::Locations::ServiceArea.all.count).to eq 1
      end
    end

    describe 'zipcode geographic rating area' do
      before :each do
        allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(setting: double(item: 'zipcode')))
      end

      context 'success' do
        let(:params) do
          {
            file: file,
            year: year,
            row_data_begin: 13
          }
        end

        before do
          ::Operations::Products::ImportCountyZip.new.call(params.merge({file: cz_file, import_timestamp: DateTime.now}))
        end

        context 'serves entire state' do

          it 'should create service area object' do
            @result = subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(county_zip_ids: []).count).to eq(1)
          end

          it 'should not create service area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "MAS002", issuer_hios_id: '12234', issuer_profile_id: issuer_profile.id, issuer_provided_title: 'Select Care ', county_zip_ids: [])
            subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(county_zip_ids: []).count).to eq(1)
          end
        end

        context 'does not serve entire state' do

          it 'should return success' do
            @result = subject.call(params)
            expect(@result.success?).to eq true
          end

          it 'should create service area objects' do
            @result = subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(:county_zip_ids.ne => []).count).to eq(1)
          end

          it 'should not create service area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "MAS002", issuer_hios_id: '12234', issuer_profile_id: issuer_profile.id, issuer_provided_title: 'Select Care ')
            subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(:county_zip_ids.ne => []).count).to eq(1)
          end
        end
      end

      context 'failure' do

        it 'should return missing file' do
          result = subject.call({})
          expect(result.failure).to eq('Missing File')
        end

        it 'should return missing year' do
          result = subject.call({ file: file })
          expect(result.failure).to eq('Missing Year')
        end

        it 'should return missing timestamp' do
          result = subject.call({ file: file, year: year })
          expect(result.failure).to eq('Missing Row data begins with')
        end

        it 'should not create RatingArea object' do
          subject.call({ file: file, row_data_begin: 13 })
          expect(::BenefitMarkets::Locations::ServiceArea.all.count).to be_zero
        end
      end
    end

    describe 'county geographic rating area' do

      before :each do
        allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(setting: double(item: 'county')))
      end

      context 'success' do
        let(:params) do
          {
            file: file,
            year: year,
            row_data_begin: 13
          }
        end

        before do
          ::Operations::Products::ImportCountyZip.new.call(params.merge({file: cz_file, import_timestamp: DateTime.now}))
        end

        context 'serves entire state' do

          it 'should create service area object' do
            @result = subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(county_zip_ids: []).count).to eq(1)
          end

          it 'should not create service area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "MAS002", issuer_hios_id: '12234', issuer_profile_id: issuer_profile.id, issuer_provided_title: 'Select Care ', county_zip_ids: [])
            subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(county_zip_ids: []).count).to eq(1)
          end
        end

        context 'does not serve entire state' do

          it 'should return success' do
            @result = subject.call(params)
            expect(@result.success?).to eq true
          end

          it 'should create service area objects' do
            @result = subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(:county_zip_ids.ne => []).count).to eq(1)
          end

          it 'should not create service area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "MAS002", issuer_hios_id: '12234', issuer_profile_id: issuer_profile.id, issuer_provided_title: 'Select Care ')
            subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(:county_zip_ids.ne => []).size).to eq(1)
          end
        end
      end

      context 'failure' do

        it 'should return missing file' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(result.failure).to eq('Missing File')
        end

        it 'should return missing year' do
          result = subject.call({ file: file })
          expect(result.failure).to eq('Missing Year')
        end

        it 'should return missing timestamp' do
          result = subject.call({ file: file, year: year })
          expect(result.failure).to eq('Missing Row data begins with')
        end

        it 'should not create RatingArea object' do
          subject.call({ import_timestamp: import_timestamp })
          expect(::BenefitMarkets::Locations::ServiceArea.all.count).to be_zero
        end
      end
    end

    describe 'mixed geographic rating area' do

      before :each do
        allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(setting: double(item: 'mixed')))
      end

      context 'success' do
        let(:params) do
          {
            file: file,
            year: year,
            row_data_begin: 13
          }
        end

        before do
          ::Operations::Products::ImportCountyZip.new.call(params.merge({file: cz_file, import_timestamp: DateTime.now}))
        end

        context 'serves entire state' do

          it 'should create service area object' do
            @result = subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(county_zip_ids: []).count).to eq(1)
          end

          it 'should not create service area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "MAS002", issuer_hios_id: '12234', issuer_profile_id: issuer_profile.id, issuer_provided_title: 'Select Care ', county_zip_ids: [])
            subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(county_zip_ids: []).count).to eq(1)
          end
        end

        context 'does not serve entire state' do

          it 'should return success' do
            @result = subject.call(params)
            expect(@result.success?).to eq true
          end

          it 'should create service area objects' do
            @result = subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(:county_zip_ids.ne => []).count).to eq(1)
          end

          it 'should not create service area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_service_area, issuer_provided_code: "MAS002", issuer_hios_id: '12234', issuer_profile_id: issuer_profile.id, issuer_provided_title: 'Select Care ')
            subject.call(params)
            expect(::BenefitMarkets::Locations::ServiceArea.where(:county_zip_ids.ne => []).size).to eq(1)
          end
        end
      end

      context 'failure' do

        it 'should return missing file' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(result.failure).to eq('Missing File')
        end

        it 'should return missing year' do
          result = subject.call({ file: file })
          expect(result.failure).to eq('Missing Year')
        end

        it 'should return missing row_data_begin' do
          result = subject.call({ file: file, year: year })
          expect(result.failure).to eq('Missing Row data begins with')
        end

        it 'should not create RatingArea object' do
          subject.call({ year: year })
          expect(::BenefitMarkets::Locations::ServiceArea.all.count).to be_zero
        end
      end
    end
  end
end
