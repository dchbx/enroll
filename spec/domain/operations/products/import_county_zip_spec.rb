# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::ImportCountyZip, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'clients with geographic rating areas' do
    let(:import_timestamp) { DateTime.now }
    let(:file) { 'spec/test_data/plan_data/rating_areas/county_zipcode.xlsx' }

    describe 'single geographic rating area' do
      let(:params) do
        {
          file: file,
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

      it 'should not create any county zip objects' do
        expect(::BenefitMarkets::Locations::CountyZip.all.count).to be_zero
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
            import_timestamp: import_timestamp
          }
        end

        context 'without existing records' do
          before do
            @result = subject.call(params)
          end

          it 'should return success' do
            expect(@result.success?).to eq true
          end

          it 'should create CountyZip objects' do
            expect(::BenefitMarkets::Locations::CountyZip.all.count).to eq(10)
          end

          it 'should create CountyZip objects without county name' do
            expect(::BenefitMarkets::Locations::CountyZip.all.pluck(:county_name).uniq).to eq([nil])
          end
        end

        context 'with existing records' do

          it 'should return success' do
            result = subject.call(params)
            expect(result.success?).to eq true
          end

          it 'should not create county zip objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_county_zip, zip: '01001')
            subject.call(params)
            expect(::BenefitMarkets::Locations::CountyZip.where(zip: '01001').size).to eq(1)
          end
        end
      end

      context 'failure' do

        it 'should return missing file' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(result.failure).to eq('Missing File')
        end

        it 'should return missing timestamp' do
          result = subject.call({ file: import_timestamp })
          expect(result.failure).to eq('Missing Import TimeStamp')
        end

        it 'should not create CountyZip object' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(::BenefitMarkets::Locations::CountyZip.all.count).to be_zero
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
            import_timestamp: import_timestamp
          }
        end

        context 'without existing records' do
          before do
            @result = subject.call(params)
          end

          it 'should return success' do
            expect(@result.success?).to eq true
          end

          it 'should create CountyZip objects' do
            expect(::BenefitMarkets::Locations::CountyZip.all.count).to eq(5)
          end

          it 'should create CountyZip objects without zipcode' do
            expect(::BenefitMarkets::Locations::CountyZip.all.pluck(:zip).uniq).to eq([nil])
          end
        end

        context 'with existing records' do

          it 'should return success' do
            result = subject.call(params)
            expect(result.success?).to eq true
          end

          it 'should not create county zip objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_county_zip, county_name: 'Hampden')
            subject.call(params)
            expect(::BenefitMarkets::Locations::CountyZip.where(county_name: 'Hampden').size).to eq(1)
          end
        end
      end

      context 'failure' do

        it 'should return missing file' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(result.failure).to eq('Missing File')
        end

        it 'should return missing timestamp' do
          result = subject.call({ file: import_timestamp })
          expect(result.failure).to eq('Missing Import TimeStamp')
        end

        it 'should not create CountyZip object' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(::BenefitMarkets::Locations::CountyZip.all.count).to be_zero
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
            import_timestamp: import_timestamp
          }
        end

        context 'without existing records' do
          before do
            @result = subject.call(params)
          end

          it 'should return success' do
            expect(@result.success?).to eq true
          end

          it 'should create CountyZip objects' do
            expect(::BenefitMarkets::Locations::CountyZip.all.count).to eq(14)
          end

          it 'should create CountyZip objects with zipcode & county' do
            expect(::BenefitMarkets::Locations::CountyZip.where(county_name: nil).size).to eq(0)
            expect(::BenefitMarkets::Locations::CountyZip.where(zip: nil).size).to eq(0)
          end
        end

        context 'with existing records' do

          it 'should return success' do
            result = subject.call(params)
            expect(result.success?).to eq true
          end

          it 'should not create county zip objects if already exists' do
            FactoryBot.create(:benefit_markets_locations_county_zip, county_name: 'Hampden', zip: '01001')
            subject.call(params)
            expect(::BenefitMarkets::Locations::CountyZip.where(county_name: 'Hampden', zip: '01001').size).to eq(1)
          end
        end
      end

      context 'failure' do

        it 'should return missing file' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(result.failure).to eq('Missing File')
        end

        it 'should return missing timestamp' do
          result = subject.call({ file: import_timestamp })
          expect(result.failure).to eq('Missing Import TimeStamp')
        end

        it 'should not create CountyZip object' do
          result = subject.call({ import_timestamp: import_timestamp })
          expect(::BenefitMarkets::Locations::CountyZip.all.count).to be_zero
        end
      end
    end
  end
end
