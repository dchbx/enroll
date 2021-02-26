# frozen_string_literal: true

#insured/families/inbox?tab=messages
class IvlDocumentsPage

  def self.download_tax_docs_btn
    '.interaction-click-control-download-tax-documents'
  end

  def self.first_message
    '.msg-inbox-unread'
  end

  def self.inbox_link
    '.interaction-click-control-inbox'
  end

  def self.deleted_link
    '.interaction-click-control-deleted'
  end

  def self.trash_can_icon
    '.fa-trash-alt'
  end

  def self.successfully_deleted_msg
    'Successfully deleted inbox message.'
  end

  def self.medicaid_and_tax_credits
    '.interaction-click-control-medicaid---tax-credits'
  end
end