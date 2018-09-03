class PaymentTransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  include OneLogin::RubySaml

  def generate_saml_response
    hbx_enrollment = ::HbxEnrollment.by_hbx_id(params[:enrollment_id]).first
    payment = PaymentTransaction.build_payment_instance(hbx_enrollment)
    saml_generator = OneLogin::RubySaml::SamlGenerator.new(payment.payment_transaction_id, hbx_enrollment)
    response_doc = saml_generator.build_saml_response
    @saml_response = saml_generator.encode_saml_response(response_doc)
    render json: {"SAMLResponse": @saml_response}
  end
end
