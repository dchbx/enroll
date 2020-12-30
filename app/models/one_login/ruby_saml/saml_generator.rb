require 'onelogin/ruby-saml/logging'

require 'onelogin/ruby-saml/saml_message'
require 'onelogin/ruby-saml/utils'

require 'securerandom'

require 'onelogin/ruby-saml/error_handling'

require 'xml_security/document'

# Only supports SAML 2.0
module OneLogin
  module RubySaml
    class SamlGenerator < SamlMessage
      REQUIRED_ATTRIBUTES = ['Payment Transaction ID', 'Market Indicator', 'Assigned QHP Identifier', 'Total Amount Owed', 'Premium Amount Total', 'APTC Amount',
                             'Proposed Coverage Effective Date', 'First Name', 'Last Name', 'Street Name 1', 'Street Name 2', 'City Name', 'State', 'Zip Code',
                             'Contact Email Address', 'Subscriber Identifier', 'Additional Information'].freeze
      ASSERTION = 'urn:oasis:names:tc:SAML:2.0:assertion'
      PROTOCOL = 'urn:oasis:names:tc:SAML:2.0:protocol'
      SUCCESS =  'urn:oasis:names:tc:SAML:2.0:status:Success'
      NAME_ID_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'
      SENDER_VOUCHES = 'urn:oasis:names:tc:SAML:2.0:cm:sendervouches'
      BEARER = 'urn:oasis:names:tc:SAML:2.0:cm:bearer'.freeze
      NAME_FORMAT = 'urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'
      PASSWORD = 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport'.freeze

      attr_reader :transaction_id, :hbx_enrollment, :private_key, :cert

      def initialize(transaction_id, hbx_enrollment)
        @transaction_id = transaction_id
        @hbx_enrollment = hbx_enrollment

        if Rails.env.production?
          @private_key = OpenSSL::PKey::RSA.new(File.read(SamlInformation.kp_pay_now_private_key_location))
          @cert = OpenSSL::X509::Certificate.new(File.read(SamlInformation.kp_pay_now_x509_cert_location))
        else
          @private_key = OpenSSL::PKey::RSA.new(File.read(Rails.root.join('spec', 'test_data').to_s + '/test_wfpk.pem'))
          @cert = OpenSSL::X509::Certificate.new(File.read(Rails.root.join('spec', 'test_data').to_s + '/test_x509.pem'))
        end
      end

      def build_saml_response
        time = Time.now.utc.iso8601
        signature_method = XMLSecurity::Document::RSA_SHA256
        digest_method = XMLSecurity::Document::SHA256

        response_doc = XMLSecurity::Document.new
        # assertion_doc = XMLSecurity::Document.new

        root = response_doc.add_element 'samlp:Response', { 'xmlns:samlp' => PROTOCOL }
        root.attributes['ID'] = "_#{generate_uuid}"
        # root.attributes['Issuer'] = SamlInformation.kp_pay_now_issuer
        root.attributes['IssueInstant'] = time
        root.attributes['Version'] = '2.0'
        root.attributes['Destination'] = SamlInformation.kp_pay_now_url

        issuer = root.add_element 'saml:Issuer', { 'xmlns:saml' => ASSERTION }
        #issuer.attributes['Format'] = NAME_ID_FORMAT
        issuer.text = SamlInformation.kp_pay_now_issuer

        # add success message
        status = root.add_element 'samlp:Status'

        # success status code
        status_code = status.add_element 'samlp:StatusCode'
        status_code.attributes['Value'] = SUCCESS

        # assertion
        assertion = root.add_element 'saml:Assertion', {'xmlns:saml' =>  ASSERTION }
        assertion.attributes['ID'] =  "_#{generate_uuid}"
        assertion.attributes['IssueInstant'] =  time
        assertion.attributes['Version'] = '2.0'

        issuer = assertion.add_element 'saml:Issuer' #, { 'Format' => NAME_ID_FORMAT }
        issuer.text = SamlInformation.kp_pay_now_issuer

        # subject
        subject = assertion.add_element 'saml:Subject'
        name_id = subject.add_element 'saml:NameID', { 'Format' => NAME_ID_FORMAT }
        name_id.text = @hbx_enrollment.hbx_id

        # subject confirmation
        subject_confirmation = subject.add_element 'saml:SubjectConfirmation', { 'Method' => BEARER }
        confirmation_data = subject_confirmation.add_element 'saml:SubjectConfirmationData'
        confirmation_data.attributes['NotOnOrAfter'] = not_on_or_after_condition.to_s
        confirmation_data.attributes['Recipient'] = SamlInformation.kp_pay_now_url

        # conditions
        conditions = assertion.add_element 'saml:Conditions', { 'NotBefore' => not_before.to_s,  'NotOnOrAfter' => not_on_or_after_condition.to_s }
        audience_restriction = conditions.add_element 'saml:AudienceRestriction'
        audience = audience_restriction.add_element 'saml:Audience'
        audience.text = SamlInformation.kp_pay_now_audience

        # auth statements
        auth_statement = assertion.add_element 'saml:AuthnStatement', { 'AuthnInstant' => "#{now_iso}",  'SessionIndex' => "_#{generate_uuid}", 'SessionNotOnOrAfter' => "#{not_on_or_after_condition}" }
        auth_context = auth_statement.add_element 'saml:AuthnContext'
        auth_class_reference = auth_context.add_element 'saml:AuthnContextClassRef'
        auth_class_reference.text = PASSWORD

        # attributes
        attribute_statement = assertion.add_element 'saml:AttributeStatement'

        REQUIRED_ATTRIBUTES.each do |attr_name|
          attribute = attribute_statement.add_element('saml:Attribute', 'NameFormat' => NAME_FORMAT)
          attribute.attributes['Name'] = attr_name
          value = attribute.add_element 'saml:AttributeValue'
          value.text = set_attribute_values(attr_name, @hbx_enrollment)
        end

        # sign the assertion
        response_doc.sign_document(@private_key, @cert, signature_method, digest_method)
        # assertion = root.add_element assertion

        response_doc
      end

      def set_attribute_values(attr_name, hbx_enrollment)
        case attr_name
        when 'Payment Transaction ID'
          hbx_enrollment.hbx_id.rjust(13, '0')
        when 'Market Indicator'
          hbx_enrollment.kind
        when 'Assigned QHP Identifier'
          hbx_enrollment.product.hios_id.gsub('-', '')
        when 'Total Amount Owed'
          hbx_enrollment.total_premium - hbx_enrollment.applied_aptc_amount.to_f
        when 'Premium Amount Total'
          hbx_enrollment.total_premium
        when 'APTC Amount'
          hbx_enrollment.applied_aptc_amount.round(2)
        when 'Proposed Coverage Effective Date'
          hbx_enrollment.effective_on.strftime('%m/%d/%Y')
        when 'First Name'
          hbx_enrollment.subscriber.person.first_name
        when 'Last Name'
          hbx_enrollment.subscriber.person.last_name
        when 'Street Name 1'
          hbx_enrollment.subscriber.person.mailing_address.address_1
        when 'Street Name 2'
          hbx_enrollment.subscriber.person.mailing_address.address_2
        when 'City Name'
          hbx_enrollment.subscriber.person.mailing_address.city
        when 'State'
          hbx_enrollment.subscriber.person.mailing_address.state
        when 'Zip Code'
          hbx_enrollment.subscriber.person.mailing_address.zip
        when 'Contact Email Address'
          hbx_enrollment.subscriber.person.work_email_or_best
        when 'Subscriber Identifier'
          hbx_enrollment.subscriber.person.hbx_id.rjust(10, '0')
        when 'Additional Information'
          hbx_enrollment.hbx_enrollment_members.map(&:person).map{|person| person.first_name_last_name_and_suffix(',')}.join(';')
        end
      end

      def encode_saml_response(response_doc)
        response = ''
        response_doc.write(response)
        encode(response)
      end

      private

      def iso
        yield.iso8601
      end

      def now
        @now ||= Time.now.utc
      end

      def now_iso
        iso { now }
      end

      def not_before
        iso { now - 5 }
      end

      def not_on_or_after_condition
        iso { now + 300 }
      end

      def generate_uuid
        SecureRandom.uuid
      end
    end
  end
end

