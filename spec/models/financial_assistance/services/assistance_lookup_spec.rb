require 'rails_helper'

RSpec.describe "AssistanceLookup" do

  let(:person_attr) {{first_name: "test", last_name: "test2", ssn: "8746537829", dob: "2000/09/01"}}

  context 'service' do
    subject do
      FinancialAssistance::Services::AssistanceLookup.new(person_attr)
    end

    before do
      allow(subject).to receive(:curam_response).and_return true
      allow(subject).to receive(:acdes_response).and_return true
    end

    context 'eligible_for_assistance?' do
      it 'should return status and message' do
        expect(subject.eligible_for_assistance?).to eq [false, "faa.acdes_lookup"]
      end
    end

    context 'curam_lookup' do
      it 'return curam status' do
        expect(subject.curam_lookup).to eq false
      end
    end

    context 'acdes_lookup' do
      it 'return acdes status' do
        expect(subject.acdes_lookup).to eq false
      end
    end
  end
end
