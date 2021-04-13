# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::Operations::BrokerAgencies::New, dbclean: :after_each do


  describe '#call' do

    let(:person) { FactoryBot.create(:person) }

    subject do
      described_class.new.call(params)
    end

    context 'Failure' do

      context 'no params passed' do
        let(:params)  { {} }
        it 'should raise error if profile type is not passed' do
          expect(subject).to be_failure
          expect(subject.failure).to eq({:message => ["Missing profile type"]})
        end
      end

      context 'params with invalid profile type passed' do
        let(:params)  { {profile_type: 'test'} }
        it 'should raise error if profile type is not passed' do
          expect(subject).to be_failure
          expect(subject.failure).to eq({:message => ['Invalid profile type']})
        end
      end
    end

    context 'when person id is not passed' do
      let(:params)  { {profile_type: 'broker_agency'} }

      it 'should create new open struct object with keys' do
        expect(subject).to be_success
      end

      it 'should create new open struct object with keys' do
        expect(subject.value!).to be_a OpenStruct
        expect(subject.value!.staff_roles.first.first_name).to be nil
      end
    end

    context 'when person id is passed' do
      let(:params)  { {profile_type: 'broker_agency', person_id: person.id.to_s} }

      it 'should create new open struct object with keys' do
        expect(subject).to be_success
      end

      it 'should create new open struct object with keys' do
        expect(subject.value!).to be_a OpenStruct
        expect(subject.value!.staff_roles.first.first_name).to be_present
      end
    end
  end
end
