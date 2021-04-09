# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::ImportRatingArea, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'clients with geographic rating areas' do

    let(:import_timestamp) { DateTime.now }
    let(:file) { 'spec/test_data/plan_data/rating_areas/county_zipcode.xlsx' }
    let(:year) { TimeKeeper.date_of_record.year }

    describe 'single geographic rating area' do
      let(:params) do
        {
          file: file,
          year: year,
          import_timestamp: import_timestamp
        }
      end

      before :each do
        allow(EnrollRegistry).to receive(:[]).with(:enroll_app).and_return(double(setting: double(item: 'single')))
      end

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to eq true
      end

      it 'should create one rating area' do
        subject.call(params)
        expect(::BenefitMarkets::Locations::RatingArea.all.count).to eq 1
      end

      it 'should not create rating area if there is an existing one' do
        FactoryBot.create(:benefit_markets_locations_rating_area, exchange_provided_code: "R-#{Settings.aca.state_abbreviation}001", county_zip_ids: [])
        subject.call(params)
        expect(::BenefitMarkets::Locations::RatingArea.all.count).to eq 1
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
            import_timestamp: import_timestamp
          }
        end

        before do
          ::Operations::Products::ImportCountyZip.new.call(params)
        end

        context 'without existing records' do
          before do
            @result = subject.call(params)
          end

          it 'should return success' do
            expect(@result.success?).to eq true
          end

          it 'should create RatingArea objects' do
            expect(::BenefitMarkets::Locations::RatingArea.all.count).to eq(7)
          end
        end

        context 'with existing records' do

          it 'should return success' do
            result = subject.call(params)
            expect(result.success?).to eq true
          end

          it 'should not create rating area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_rating_area, exchange_provided_code: 'Rating Area 1')
            subject.call(params)
            expect(::BenefitMarkets::Locations::RatingArea.where(exchange_provided_code: 'Rating Area 1').size).to eq(1)
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
          expect(result.failure).to eq('Missing Import TimeStamp')
        end

        it 'should not create RatingArea object' do
          subject.call({ file: file, import_timestamp: import_timestamp })
          expect(::BenefitMarkets::Locations::RatingArea.all.count).to be_zero
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
            import_timestamp: import_timestamp
          }
        end

        before do
          ::Operations::Products::ImportCountyZip.new.call(params)
        end

        context 'without existing records' do
          before do
            @result = subject.call(params)
          end

          it 'should return success' do
            expect(@result.success?).to eq true
          end

          it 'should create RatingArea objects' do
            expect(::BenefitMarkets::Locations::RatingArea.all.count).to eq(7)
          end
        end

        context 'with existing records' do

          it 'should return success' do
            result = subject.call(params)
            expect(result.success?).to eq true
          end

          it 'should not create rating area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_rating_area, exchange_provided_code: 'Rating Area 1')
            subject.call(params)
            expect(::BenefitMarkets::Locations::RatingArea.where(exchange_provided_code: 'Rating Area 1').size).to eq(1)
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
          expect(result.failure).to eq('Missing Import TimeStamp')
        end

        it 'should not create RatingArea object' do
          subject.call({ import_timestamp: import_timestamp })
          expect(::BenefitMarkets::Locations::RatingArea.all.count).to be_zero
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
            import_timestamp: import_timestamp
          }
        end

        before do
          ::Operations::Products::ImportCountyZip.new.call(params)
        end

        context 'without existing records' do
          before do
            @result = subject.call(params)
          end

          it 'should return success' do
            expect(@result.success?).to eq true
          end

          it 'should create RatingArea objects' do
            expect(::BenefitMarkets::Locations::RatingArea.all.count).to eq(7)
          end
        end

        context 'with existing records' do

          it 'should return success' do
            result = subject.call(params)
            expect(result.success?).to eq true
          end

          it 'should not create rating area objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_rating_area, exchange_provided_code: 'Rating Area 1')
            subject.call(params)
            expect(::BenefitMarkets::Locations::RatingArea.where(exchange_provided_code: 'Rating Area 1').size).to eq(1)
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
          expect(result.failure).to eq('Missing Import TimeStamp')
        end

        it 'should not create RatingArea object' do
          subject.call({ import_timestamp: import_timestamp })
          expect(::BenefitMarkets::Locations::RatingArea.all.count).to be_zero
        end
      end
    end
  end
end
