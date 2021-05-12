require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.shared_examples "tracked history" do |field, new_value|
  it 'tracks creation' do
    expect(subject.history_tracks.first['action']).to eq('create')
  end

  it 'tracks updates' do
    old_value = subject.send(field)

    expect do
      subject.update_attributes! field => new_value
    end.to change { subject.history_tracks.count }.by(1)

    expect(subject.history_tracks.last['original'][field]).to eql(old_value)
  end
end

describe Person, :dbclean => :after_each do
  let(:person) { FactoryBot.create :person }
  let!(:original_name) { person.full_name }

  context "after updating" do
    before do
      person.update_attributes! first_name: "Something", last_name: "Different"
    end

    it 'changes the name' do
      expect(person.full_name).to eq('Something Different')
    end

    it 'has a history_track' do
      expect(person.history_tracks.count).to be > 1
    end

    it 'tracks the changes' do
      expect(person.history_tracks.last['original'].slice('first_name', 'last_name').values.join(' ')).to eql(original_name)
    end
  end

  context "after updating an address" do
    subject do
      person.addresses.create! address_1: '1st St NE',
        city: 'Washington',
        state: 'DC',
        zip: '20001',
        kind: 'home'
    end

    include_examples 'tracked history', 'address_1', '2nd St NE'
  end

  context 'updating a consumer role' do
    subject do
      person.create_consumer_role marital_status: 'single', is_applicant: false
    end

    include_examples 'tracked history', 'marital_status', 'married'
  end

  context 'updating a resident role' do
    subject do
      person.create_resident_role dob: person.dob, gender: 'male', is_state_resident: true
    end

    include_examples 'tracked history', 'is_state_resident', false
  end

  context 'with an individual market transition' do
    subject do
      person.individual_market_transitions.create! role_type: 'resident', reason_code: 'generating_resident_role'
    end

    include_examples 'tracked history', 'reason_code', 'eligibility_documents_provided'
  end

  context 'of a broker role' do
    subject { FactoryBot.create :broker_role }

    include_examples 'tracked history', 'provider_kind', 'assister'
  end

  context 'of a hbx staff role' do
    subject { FactoryBot.create :hbx_staff_role, person: person }

    include_examples 'tracked history', 'job_title', 'Plumber'
  end

  context 'of a csr role' do
    subject { FactoryBot.create :csr_role, person: person }

    include_examples 'tracked history', 'shift', 'Testing'
  end

  context 'of an assister role' do
    subject { FactoryBot.create :assister_role, person: person }

    include_examples 'tracked history', 'organization', 'Testing'
  end

  context 'of an employer staff role' do
    subject { FactoryBot.create :employer_staff_role, person: person }

    include_examples 'tracked history', 'bookmark_url', 'Testing'
  end

  context 'of a broker agency staff role' do
    let(:broker_agency_profile) { FactoryBot.create :broker_agency_profile }
    subject { FactoryBot.create :broker_agency_staff_role, broker_agency_profile: broker_agency_profile }

    include_examples 'tracked history', 'reason', 'Testing'
  end

  context 'of an employee role' do
    subject { FactoryBot.create :employee_role }

    include_examples 'tracked history', 'is_active', false
  end

  context 'of a general agency staff role' do
    subject { FactoryBot.create :general_agency_staff_role }

    include_examples 'tracked history', 'npn', '22222222'
  end

  context 'of a person relationship' do
    let(:relative) { FactoryBot.create :person }
    subject { person.person_relationships.create! kind: 'spouse', relative_id: relative.id }

    include_examples 'tracked history', 'kind', 'child'
  end

  context 'of a phone number' do
    subject { FactoryBot.create :phone, person: person }

    include_examples 'tracked history', 'kind', 'work'
  end

  context 'of an email' do
    subject { FactoryBot.create :email, kind: 'work', person: person }

    include_examples 'tracked history', 'kind', 'home'
  end

  context 'of a verification type' do
    subject { FactoryBot.create :verification_type, person: person }

    include_examples 'tracked history', 'update_reason', 'Testing'
  end
end

describe "Person LegacyVersioningRecords" do
  subject { Person.new }

  it 'creates a version field with a default value of 1' do
    expect(subject.version).to eql(1)
  end

  it 'has an array of versions' do
    expect(subject.versions).to be_kind_of(Array)
  end
end
