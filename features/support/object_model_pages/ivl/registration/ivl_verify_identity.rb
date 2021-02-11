# frozen_string_literal: true

#insured/interactive_identity_verifications/new
#insured/interactive_identity_verifications/failed_validation?step=questions&verification_transaction_id
class IvlVerifyIdentity

  def self.verify_identity_text
    'Verify Identity'
  end

  def self.pick_answer_a
    'label[for="interactive_verification_questions_attributes_0_response_id_a"] span'
  end

  def self.pick_answer_b
    'label[for="interactive_verification_questions_attributes_0_response_id_b"] span'
  end

  def self.pick_answer_c
    'label[for="interactive_verification_questions_attributes_1_response_id_c"] span'
  end

  def self.pick_answer_d
    'label[for="interactive_verification_questions_attributes_1_response_id_d"] span'
  end

  def self.submit_btn
    'input[value="Submit"]'
  end

  def self.continue_application_btn
    '.interaction-click-control-continue-application'
  end

  def self.upload_identity_docs_btn
    '#upload_identity'
  end

  def self.upload_application_docs_btn
    '#upload_application'
  end

  def self.select_file_to_upload_btn
    '#select_upload_identity'
  end

  def self.documents_faq_btn
    '.interaction-click-control-documents-faq'
  end
end