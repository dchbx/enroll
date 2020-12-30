# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::DocumentContract do

  let(:title)            { 'Title' }
  let(:creator)          { 'The Creator' }
  let(:publisher)        { 'The Publisher'}
  let(:type)             { 'Type' }
  let(:file_format)      { 'PDF' }
  let(:source)           { 'Source' }
  let(:language)         { 'English' }

  let(:missing_params)   { {title: title, creator: creator, publisher: publisher, format: file_format, language: language} }
  let(:tags)             { 'Tags'}
  let(:required_params)  { missing_params.merge({type: type, source: source}) }
  let(:invalid_params)   {required_params.merge({tags: tags})}
  let(:error_message1)   { {:type => ["is missing"], :source => ["is missing"]} }
  let(:error_message2)   { {:tags => ["must be an array"]} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  context "Given valid required parameters" do

    context "with a required only" do
      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end

    context "with all params" do
      let(:all_params) do
        required_params.merge({ subject: 'subject', description: 'description', contributor: 'contributor',
                                date: Time.zone.today.to_s, identifier: 'identifier', relation: 'relation',
                                coverage: 'coverage', rights: 'rights', tags: [{}], size: 'size'})
      end

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end