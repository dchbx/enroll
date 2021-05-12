# frozen_string_literal: true

RSpec.describe Operations::Families::CreateOrUpdateFamilyMember, type: :model, dbclean: :after_each do
  let!(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      hbx_id: '20944967',
                      last_name: 'Test',
                      first_name: 'Domtest34',
                      ssn: '243108282',
                      dob: Date.new(1984, 3, 8))
  end

  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

  let!(:applicant_params) {
    {:_id => BSON::ObjectId('5f5ecf00d73697f046c926fe'),
     :family_id => BSON::ObjectId(family.id),
     :person_hbx_id => '77a0be350dd1437ca5ba2259fdddb982',
     :first_name => 'mem30',
     :last_name => '30',
     :gender => 'male',
     :dob => '2000-09-17 00:00:00 UTC',
     :is_incarcerated => true,
     :ethnicity => ['White', 'Black or African American', 'Asian Indian', 'Chinese', 'Mexican', 'Mexican American'],
     :tribal_id => '123213123',
     :no_dc_address => false,
     :is_homeless => false,
     :is_temporarily_out_of_state => false,
     :citizen_status => 'alien_lawfully_present',
     :is_consumer_role => true,
     :same_with_primary => true,
     :is_applying_coverage => true,
     :vlp_subject => 'I-94 (Arrival/Departure Record)',
     :i94_number => '65436789098',
     :sevis_id => '3456789876',
     :expiration_date => '2020-09-30 00:00:00 UTC',
     :ssn => '873672163',
     :relationship => 'unrelated',
     :addresses =>
         [{'address_1' => '123 NE',
           'address_2' => '',
           'address_3' => '',
           'county' => '',
           'country_name' => '',
           'kind' => 'home',
           'city' => 'was',
           'state' => 'DC',
           'zip' => '12321'}],
     :emails => [{'kind' => 'home', 'address' => 'mem30@dc.gov'}],
     :phones =>
         [{'kind' => 'home', 'country_code' => '', 'area_code' => '213', 'number' => '2131322', 'extension' => '', 'full_phone_number' => '2132131322'},
          {'kind' => 'mobile', 'country_code' => '', 'area_code' => '213', 'number' => '2131322', 'extension' => '', 'full_phone_number' => '2132131322'}]}
  }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'for success flow' do

    before do
      @result = subject.call(applicant_params)
      family.reload
      @person = Person.by_hbx_id(applicant_params[:hbx_id]).first
    end

    context 'success' do
      it 'should return success' do
        expect(@result).to be_a Dry::Monads::Result::Success
      end

      it 'should create person' do
        expect(@person).not_to eq nil
      end

      it 'should create family member' do
        expect(family.family_members.count).to eq 2
      end

      it 'should create consumer role' do
        expect(@person.consumer_role.present?).to be_truthy
      end

      it 'should create vlp documents' do
        expect(@person.consumer_role.vlp_documents.present?).to be_truthy
      end
    end
  end

  context 'for failure flow' do
    before do
      @result = subject.call(applicant_params.except(:family_id))
      family.reload
      @person = Person.by_hbx_id(applicant_params[:hbx_id]).first
    end

    context 'failure' do
      it 'should return failure' do
        expect(@result).to be_a Dry::Monads::Result::Failure
      end

      it 'should not create person' do
        expect(@person).to eq nil
      end

      it 'should not create family member' do
        expect(family.family_members.count).not_to eq 2
      end
    end
  end
end
