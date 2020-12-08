require 'rails_helper'

RSpec.describe CensusDependent, :type => :model do
  it { should validate_presence_of :employee_relationship }

  let(:first_name) { "Lynyrd" }   
  let(:middle_name) { "R" }   
  let(:last_name) { "Skynyrd" }   
  let(:name_sfx) { "PhD" }   
  let(:dob) { TimeKeeper.date_of_record }
  let(:ssn) { "230987654" }
  let(:gender) { "male" }
  let(:employee_relationship) { "spouse" }

  let(:dependent) {
    CensusDependent.new(
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_sfx: name_sfx,
        ssn: ssn,
        dob: dob,
        gender: gender,
        employee_relationship: employee_relationship
      )
  }

  context 'spouse' do
    it 'properly instantiates the class' do
      expect(dependent.first_name).to eq first_name
      expect(dependent.middle_name).to eq middle_name
      expect(dependent.last_name).to eq last_name
      expect(dependent.name_sfx).to eq name_sfx
      expect(dependent.ssn).to eq ssn
      expect(dependent.dob).to eq dob
      expect(dependent.gender).to eq gender
      expect(dependent.employee_relationship).to eq employee_relationship

      expect(dependent.errors.messages.size).to eq 0
    end

    it 'fails unless provided with a gender' do
      dependent.gender = nil
      expect(dependent.valid?).to eq false
      expect(dependent).to have_errors_on(:gender)
    end

    it 'fails when provided a bogus gender' do
      dependent.gender = "OMG SO NOT A GENDER DUDE"
      expect(dependent.valid?).to eq false
      expect(dependent).to have_errors_on(:gender)
    end

    it 'fails unless provided with a proper employee_relationship' do
      dependent.employee_relationship = nil
      expect(dependent.valid?).to eq false
      expect(dependent).to have_errors_on(:employee_relationship)
    end
  end

  context 'dependent' do
    let(:dob) { TimeKeeper.date_of_record - 15.years }
    let!(:census_employee) { FactoryBot.create(:census_employee) }

    before do
      census_employee.census_dependents.destroy_all
      census_employee.census_dependents.create!(first_name: 'Mary', last_name: 'Doe', dob: dob, employee_relationship: 'child_under_26', gender: 'female')
    end

    it 'does not allow the census employee to have multiple child dependents with the same first and last name' do
      expect(census_employee.census_dependents.build(first_name: 'Mary', last_name: 'Doe', dob: dob, employee_relationship: 'child_under_26', gender: 'female')).to_not be_valid
    end
  end
end
