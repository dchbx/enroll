# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::AvailableEligibilityService, type: :model, :dbclean => :after_each do
  context 'initialize' do
    it { expect(described_class.respond_to?(:new)).to eq true }

    it { expect(described_class.new('enrollment_id', TimeKeeper.date_of_record)).to be_a Services::AvailableEligibilityService }

    it { expect{described_class.new}.to raise_error(ArgumentError) }
  end

  context 'available_eligibility' do
    it { expect(described_class.new('enrollment_id', TimeKeeper.date_of_record).respond_to?(:available_eligibility)).to eq true }

    it 'should raise error for bad enrollment id' do
      service_instance = described_class.new('enrollment_id', TimeKeeper.date_of_record)
      error_message = 'Cannot find a valid enrollment with given enrollment id'
      expect{service_instance.available_eligibility}.to raise_error(RuntimeError, error_message)
    end
  end
end
