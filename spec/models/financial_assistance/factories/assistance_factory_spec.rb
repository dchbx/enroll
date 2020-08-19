require 'rails_helper'

RSpec.describe "AssistanceFactory" do

  let(:person) {FactoryGirl.create(:person)}

  context 'service' do
    subject do
      FinancialAssistance::Factories::AssistanceFactory.new(person)
    end

    context 'search_existing_assistance' do
      it 'should return is_eligibile_for_assistance status and message' do
        expect(subject.search_existing_assistance).to eq [true, nil]
      end
    end
  end
end
