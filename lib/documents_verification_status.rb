# frozen_string_literal: true

module DocumentsVerificationStatus
  def verification_type_status(type, member)
    consumer = member.consumer_role
    if consumer.vlp_authority == "curam" && consumer.fully_verified?
      "External source"
    else
      type.validation_status
    end
  end
end