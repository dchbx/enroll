# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::VlpV37Contract, type: :model, dbclean: :after_each do

  context 'bad subject' do
    before do
      @result = subject.call({subject: 'subject'})
    end

    it 'should return errors' do
      expect(@result.errors.to_h).not_to be_empty
    end

    it 'should return errors' do
      expect(@result.errors.to_h).to eq({ subject: ["Invalid VLP Document type"] })
    end
  end

  context "I-327 (Reentry Permit)" do
    let(:valid_params) do
      { subject: 'I-327 (Reentry Permit)', alien_number: '123456789' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:alien_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["Alien Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'alien_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({alien_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["length must be 9"] })
        end
      end
    end
  end

  context "I-551 (Permanent Resident Card)" do
    let(:valid_params) do
      { subject: 'I-551 (Permanent Resident Card)', alien_number: '123456789', card_number: '1234567890123' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:alien_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["Alien Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'alien_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({ alien_number: '1234' }))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["length must be 9"] })
        end
      end

      context 'card_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({ card_number: '1234' }))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ card_number: ["length must be 13"] })
        end
      end
    end
  end

  context "I-571 (Refugee Travel Document)" do
    let(:valid_params) do
      { subject: 'I-571 (Refugee Travel Document)', alien_number: '123456789' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:alien_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["Alien Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'alien_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({alien_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["length must be 9"] })
        end
      end
    end
  end

  context "I-766 (Employment Authorization Card)" do
    let(:valid_params) do
      { subject: 'I-766 (Employment Authorization Card)', alien_number: '123456789', card_number: '1234567890123', expiration_date: TimeKeeper.date_of_record }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:alien_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["Alien Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'alien_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({ alien_number: '1234' }))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["length must be 9"] })
        end
      end

      context 'card_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({ card_number: '1234' }))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ card_number: ["length must be 13"] })
        end
      end
    end
  end

  context "Certificate of Citizenship" do
    let(:valid_params) do
      { subject: 'Certificate of Citizenship', citizenship_number: '123456789' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:citizenship_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ citizenship_number: ["Citizenship Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'citizenship_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({citizenship_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ citizenship_number: ["length must be within 6 - 12"] })
        end
      end
    end
  end

  context "Naturalization Certificate" do
    let(:valid_params) do
      { subject: 'Naturalization Certificate', naturalization_number: '123456789' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:naturalization_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ naturalization_number: ["Naturalization Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'naturalization_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({naturalization_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ naturalization_number: ["length must be within 6 - 12"] })
        end
      end
    end
  end

  context "Machine Readable Immigrant Visa (with Temporary I-551 Language)" do
    let(:valid_params) do
      { subject: 'Machine Readable Immigrant Visa (with Temporary I-551 Language)', passport_number: '123456789', alien_number: '123456789' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:passport_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ passport_number: ["Passport Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'passport_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({passport_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ passport_number: ["length must be within 6 - 12"] })
        end
      end
    end
  end

  context "Temporary I-551 Stamp (on passport or I-94)" do
    let(:valid_params) do
      { subject: 'Temporary I-551 Stamp (on passport or I-94)', alien_number: '123456789' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:alien_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["Alien Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'alien_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({alien_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["length must be 9"] })
        end
      end
    end
  end

  context "I-94 (Arrival/Departure Record)" do
    let(:valid_params) do
      { subject: 'I-94 (Arrival/Departure Record)', i94_number: '123456789t6' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:i94_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ i94_number: ["I94 Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'i94_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({i94_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ i94_number: ["length must be 11"] })
        end
      end
    end
  end

  context "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport" do
    let(:valid_params) do
      { subject: 'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport', i94_number: '123456789t6', passport_number: 'N000000', expiration_date: TimeKeeper.date_of_record }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:i94_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ i94_number: ["I94 Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'passport_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({passport_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ passport_number: ["length must be within 6 - 12"] })
        end
      end
    end
  end

  context "Unexpired Foreign Passport" do
    let(:valid_params) do
      { subject: 'Unexpired Foreign Passport', passport_number: 'N000000', expiration_date: TimeKeeper.date_of_record }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:passport_number))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ passport_number: ["Passport Number is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'passport_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({passport_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ passport_number: ["length must be within 6 - 12"] })
        end
      end
    end
  end

  context "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)" do
    let(:valid_params) do
      { subject: 'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)', sevis_id: '1234567890' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:sevis_id))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ sevis_id: ["Sevis ID is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'sevis_id is shorter' do
        before do
          @result = subject.call(valid_params.merge!({sevis_id: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ sevis_id: ["length must be 10"] })
        end
      end
    end
  end

  context "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)" do
    let(:valid_params) do
      { subject: 'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)', sevis_id: '1234567890' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:sevis_id))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ sevis_id: ["Sevis ID is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'sevis_id is shorter' do
        before do
          @result = subject.call(valid_params.merge!({sevis_id: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ sevis_id: ["length must be 10"] })
        end
      end
    end
  end

  context "Other (With Alien Number)" do
    let(:valid_params) do
      { subject: 'Other (With Alien Number)', alien_number: '123456789', description: 'Document with some description' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:description))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ description: ["Description is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'alien_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({alien_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ alien_number: ["length must be 9"] })
        end
      end
    end
  end

  context "Other (With I-94 Number)" do
    let(:valid_params) do
      { subject: 'Other (With I-94 Number)', i94_number: '123456789t6', description: 'Document with some description' }
    end

    context 'for success case' do
      before do
        @result = subject.call(valid_params)
      end

      it 'should be a container-ready operation' do
        expect(subject.respond_to?(:call)).to be_truthy
      end

      it 'should return Dry::Validation::Result object' do
        expect(@result).to be_a ::Dry::Validation::Result
      end

      it 'should not return any errors' do
        expect(@result.errors.to_h).to be_empty
      end
    end

    context 'for failure cases' do
      context 'missing key' do
        before do
          @result = subject.call(valid_params.except(:description))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ description: ["Description is required for VLP Document type: #{valid_params[:subject]}"] })
        end
      end

      context 'i94_number is shorter' do
        before do
          @result = subject.call(valid_params.merge!({i94_number: '1234'}))
        end

        it 'should return errors' do
          expect(@result.errors.to_h).not_to be_empty
        end

        it 'should return errors' do
          expect(@result.errors.to_h).to eq({ i94_number: ["length must be 11"] })
        end
      end
    end
  end
end
