module DocumentsVerificationStatus   
    def verification_type_status(type, member, admin=false)
    consumer = member.consumer_role
    return "curam" if (consumer.vlp_authority == "curam" && consumer.fully_verified? && admin)
    case type
      when 'Social Security Number'
        if consumer.ssn_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.ssn_rejected
          "in review"
        else
          "outstanding"
        end
      when 'American Indian Status'
        if consumer.native_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.native_rejected
          "in review"
        else
          "outstanding"
        end
      else
        if consumer.lawful_presence_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.lawful_presence_rejected
          "in review"
        else
          "outstanding"
        end
    end
  end
end