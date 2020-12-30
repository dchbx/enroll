# frozen_string_literal: true

require 'rails_helper'

module Validators
  RSpec.describe SecureMessageActionContract,  dbclean: :after_each do

    subject do
      described_class.new.call(params)
    end

    describe "given empty :subject" do

      let(:params) { { subject: '', body: 'test', actions_id: '1234', resource_id: '1234', resource_name: 'person' }}
      let(:error_message) {{:subject => ['Please enter subject']}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "given empty :body" do

      let(:params) { { subject: 'test', body: '', actions_id: '1234', resource_id: '1234', resource_name: 'person' }}
      let(:error_message) {{:body => ['Please enter content']}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "given empty :body and :subject" do

      let(:params) { { subject: '', body: '', actions_id: '1234', resource_id: '1234', resource_name: 'person' }}
      let(:error_message) {{:subject => ['Please enter subject'], :body => ['Please enter content']}}


      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "given empty :resource_id and :resource_name" do

      let(:params) { { subject: 'test', body: 'test', actions_id: '1234', resource_id: '', resource_name: '' }}
      let(:error_message) {{:resource_id => ['Unable to find the resource'], :resource_name => ['Unable to find the resource']}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "not passing :resource_id and :resource_name" do

      let(:params) { { subject: 'test', body: 'test', actions_id: '1234'}}
      let(:error_message) {{:resource_id => ['is missing'], :resource_name => ['is missing']}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "not passing :resource_id, :subject, :actions_id, :body :resource_name" do

      let(:params) { { }}
      let(:error_message) {{:resource_id => ['is missing'], :resource_name => ['is missing'], :actions_id => ['is missing'], :subject => ['is missing'], :body => ['is missing']}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.errors.to_h).to eq error_message
      end
    end

    describe "passing all values" do

      let(:params) { { subject: 'test', body: 'test', actions_id: '1234', resource_id: '1234', resource_name: 'test' }}

      it "passes" do
        expect(subject).to be_success
        expect(subject.errors.to_h).to be_empty
      end
    end
  end
end
