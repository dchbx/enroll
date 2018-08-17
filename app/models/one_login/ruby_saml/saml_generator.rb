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
      REQUIRED_ATTRIBUTES = ['Payment Transaction ID', 'Market Indicator', 'Assigned QHP Identifier', 'Total Amount Owed', 'Premium Amount Total', 'APTC Amount', 'Proposed Coverage Effective Date', 'First Name', 'Last Name', 'Partner Assigned Consumer ID','Street Name 1', 'City Name', 'State', 'Zip Code','Additional Information']
      ASSERTION = 'urn:oasis:names:tc:SAML:2.0:assertion'
      PROTOCOL = 'urn:oasis:names:tc:SAML:2.0:protocol'
      SUCCESS =  'urn:oasis:names:tc:SAML:2.0:status:Success'
      NAME_ID_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'
      SENDER_VOUCHES = 'urn:oasis:names:tc:SAML:2.0:cm:sendervouches'
      NAME_FORMAT = 'urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'
      PASSWORD = 'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'
      PRIVATE_KEY_LOCATION = '/var/www/deployments/enroll/current/config/ssl/wfpk.pem'
      X509_CERT_LOCATION = '/var/www/deployments/enroll/current/config/ssl/x509.pem'

      attr_reader :transaction_id, :hbx_enrollment, :private_key, :cert

      def initialize(transaction_id, hbx_enrollment)
        @transaction_id = transaction_id
        @hbx_enrollment = hbx_enrollment

        if Rails.env.production?
          @private_key = OpenSSL::PKey::RSA.new(File.read(PRIVATE_KEY_LOCATION))
          @cert = OpenSSL::X509::Certificate.new(File.read(X509_CERT_LOCATION))
        end
      end

      def build_saml_response
        time = Time.now.utc.iso8601
        signature_method = XMLSecurity::Document::RSA_SHA1
        digest_method = XMLSecurity::Document::SHA1

        response_doc = XMLSecurity::Document.new

        root = response_doc.add_element 'samlp:Response', { 'xmlns:samlp' => PROTOCOL }
        root.attributes['ID'] = "_#{generate_uuid}"
        root.attributes['IssueInstant'] = time
        root.attributes['Version'] = '2.0'

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

        issuer = assertion.add_element 'saml:Issuer', { 'Format' => NAME_ID_FORMAT }
        issuer.text = SamlInformation.issuer

        # sign the assertion
        response_doc.sign_document(@private_key, @cert, signature_method, digest_method)

        # subject
        subject = assertion.add_element 'saml:Subject'
        name_id = subject.add_element 'saml:NameID', { 'Format' => NAME_ID_FORMAT }
        name_id.text = 'FFM'

        # subject confirmation
        subject.add_element 'saml:SubjectConfirmation', { 'Method' => SENDER_VOUCHES }

        # conditions
        assertion.add_element 'saml:Conditions', { 'NotBefore' => "#{not_before}",  'NotOnOrAfter' => "#{not_on_or_after_condition}" }

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
        response_doc
      end

      def set_attribute_values(attr_name, hbx_enrollment)
        case attr_name
        when 'Payment Transaction ID'
          @transaction_id
        when 'Market Indicator'
          hbx_enrollment.kind
        when 'Assigned QHP Identifier'
          hbx_enrollment.plan.hios_id
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
        when 'Partner Assigned Consumer ID'
          hbx_enrollment.subscriber.person.hbx_id
        when 'Street Name 1'
          hbx_enrollment.subscriber.person.mailing_address.address_1
        when 'City Name'
          hbx_enrollment.subscriber.person.mailing_address.city
        when 'State'
          hbx_enrollment.subscriber.person.mailing_address.state
        when 'Zip Code'
          hbx_enrollment.subscriber.person.mailing_address.zip
        when 'Additional Information'
          hbx_enrollment.hbx_enrollment_members.map(&:person).map{|person| person. first_name_last_name_and_suffix(',')}.join(';')
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
        iso { now + 86400 }
      end

      def generate_uuid
        SecureRandom.uuid
      end
    end
  end
end
