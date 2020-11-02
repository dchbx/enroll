# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Validators::AddressContract,  dbclean: :after_each do
  subject do
    described_class.new.call(params)
  end

  describe "missing address1 field" do

    let(:params) do
      { kind: 'test', address_2: '1234', address_3: 'person', city: 'test', county: '', state: 'DC', zip: '12345', county_name: '' }
    end
    let(:error_message) {{:address_1 => ['is missing']}}


    it "fails" do
      expect(subject).not_to be_success
      expect(subject.errors.to_h).to eq error_message
    end
  end

  describe "missing kind field" do

    let(:params) do
      { address_1: 'test', address_2: '1234', address_3: 'person', city: 'test', county: '', state: 'DC', zip: '12345', county_name: '' }
    end
    let(:error_message) {{:kind => ['is missing']}}


    it "fails" do
      expect(subject).not_to be_success
      expect(subject.errors.to_h).to eq error_message
    end
  end

  describe "missing city field" do

    let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', county: '', state: 'DC', zip: '12345', county_name: '' }}
    let(:error_message) {{:city => ['is missing']}}


    it "fails" do
      expect(subject).not_to be_success
      expect(subject.errors.to_h).to eq error_message
    end
  end

  describe "missing state field" do

    let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', city: 'test', county: '', zip: '12345', county_name: '' }}
    let(:error_message) {{:state => ['is missing']}}


    it "fails" do
      expect(subject).not_to be_success
      expect(subject.errors.to_h).to eq error_message
    end
  end

  describe "missing zip" do

    let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', city: 'test', state: 'DC', county: '', county_name: '' }}
    let(:error_message) {{:zip => ['is missing']}}

    it "fails" do
      expect(subject).not_to be_success
      expect(subject.errors.to_h).to eq error_message
    end
  end

  describe "passing empty address_1, city, kind, state, zip" do

    let(:params) { { kind: 'test', address_1: '', address_2: '1234', address_3: 'person', city: '', state: '', zip: '', county: '', county_name: '' }}
    let(:error_message) {{:address_1 => ["must be filled"], :city => ["must be filled"], :state => ["must be filled"], :zip => ["must be filled"]}}

    it "fails" do
      expect(subject).not_to be_success
      expect(subject.errors.to_h).to eq error_message
    end
  end

  describe "all valid fields" do

    let(:params) { { kind: 'test', address_1: '1234', address_2: '1234', address_3: 'person', city: 'test', state: 'DC', zip: '12345', county: '', county_name: '' }}

    it "passes" do
      expect(subject).to be_success
    end
  end
end
