require 'rails_helper'

module OneLogin
  RSpec.describe RubySaml::SamlGenerator do
    let(:transaction_id)   { '1234' }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent) }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: 'shopping') }
    let!(:hbx_enrollment_member1) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment) }
    let!(:hbx_enrollment_member2) { FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment) }
    let(:saml_generator) { OneLogin::RubySaml::SamlGenerator.new(transaction_id,hbx_enrollment) }
    let(:test_priv_key) { OpenSSL::PKey::RSA.new(File.read("#{Rails.root.join("spec", "test_data")}" + "/test_wfpk.pem")) }
    let(:test_x509_cert) { OpenSSL::X509::Certificate.new(File.read("#{Rails.root.join("spec", "test_data")}" + "/test_x509.pem")) }

    before :each do
      saml_generator.instance_variable_set(:@private_key, test_priv_key)
      saml_generator.instance_variable_set(:@cert, test_x509_cert)
      hbx_enrollment.update_attributes(kind: 'individual')
      @saml_response = saml_generator.build_saml_response
      @noko = Nokogiri.parse(@saml_response.to_s) do |options|
        options = XMLSecurity::BaseDocument::NOKOGIRI_OPTIONS
      end
    end

    context 'initilaze saml generator with fileds required' do
      it 'should intialize the fields' do
        expect(saml_generator.transaction_id). to eq transaction_id
        expect(saml_generator.hbx_enrollment). to eq hbx_enrollment
      end
    end

    context '#build_saml_response' do
      let(:assertion) { 'urn:oasis:names:tc:SAML:2.0:assertion' }
      let(:protocol) { 'urn:oasis:names:tc:SAML:2.0:protocol' }
      let(:name_id_format) { 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified' }
      let(:sender_token) { 'urn:oasis:names:tc:SAML:2.0:cm:sendervouches' }
      it 'should build return a string with encoded value' do
        expect(@saml_response.class). to eq XMLSecurity::Document
      end

      it 'should generate saml response with version 2.0' do
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['Version'].value).to eq '2.0'
      end

      it 'saml response should contain ID, Issuer Instant and Version attributes present' do
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['ID'].present?).to eq true
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['Version'].present?).to eq true
        expect(@noko.xpath('//samlp:Response').map(&:attributes)[0]['IssueInstant'].present?).to eq true
      end

      it 'should assert valid arguments to Response tag' do
        expect(@noko.xpath('//samlp:Response').first.namespace.href). to eq protocol
      end

      it 'should assert valid arguments to assertion tag' do
        expect(@noko.xpath('//samlp:Response').children[1].namespace.href). to eq assertion
        expect(@noko.xpath('//samlp:Response').children[1].name). to eq 'Assertion'
      end

      it 'assertion should have issuer child node present' do
        assertion = @noko.xpath('//samlp:Response').children[1]
        expect(assertion.children[0].name). to eq 'Issuer'
        expect(assertion.children[0].attributes.first[1].name). to eq 'Format'
        expect(assertion.children[0].attributes.first[1].value). to eq name_id_format
      end

      it 'name id should have the format and value present' do
        assertion = @noko.xpath('//samlp:Response').children[1]
        subject = assertion.children[2]
        expect(subject.children[0].attributes['Format'].value). to eq name_id_format
        expect(subject.children[0].children.first.text). to eq 'FFM'
      end

      it 'assertion should have signature node present' do
        assertion = @noko.xpath('//samlp:Response').children[1]
        expect(assertion.children[1].name). to eq 'Signature'
        expect(assertion.children[1].namespace.prefix). to eq 'ds'
      end

      it 'should have send vouches as subject confirmation method' do
        assertion = @noko.xpath('//samlp:Response').children[1]
        expect(assertion.children[2].children[1].attributes['Method'].name). to eq 'Method'
        expect(assertion.children[2].children[1].attributes['Method'].value). to eq sender_token
      end

      it 'should sign the assertion and not the response' do
        assertion = @noko.xpath('//samlp:Response').children[1]
        expect(assertion.children.map(&:name)).to include('Signature')
      end
    end

    context '#encode_response' do
      it 'should return encoded value with String class' do
        encoded_response = saml_generator.encode_saml_response(@saml_response)
        expect(encoded_response.class). to eq String
      end
    end
  end
end