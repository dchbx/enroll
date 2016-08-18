xml.instruct!
xml.ESIMECResponse(:'xmlns:xs' => "http://www.w3.org/2001/XMLSchema",
                   :xmlns => "http://openhbx.org/api/terms/1.0") do
  xml.applicant_response_set do
    xml.applicant_response do
      xml.response_person do
        xml.identification_id @person.ssn
      end
      xml.applicant_MEC_information do
        xml.insurance_applicant_requested_coverage do
          xml.start_date @start_date.strftime("%Y-%m-%d")
          xml.end_date @end_data.strftime("%Y-%m-%d")
        end
        xml.insurance_applicant_response do
          xml.insurance_applicant_eligible_employer_sponsored_insurance_indicator true
          xml.insurance_applicant_insured_indicator true
        end
        xml.inconsistency_indicator true
        xml.monthly_premium_amount do
          xml.employee_premium_amount do
            xml.insurance_premium_amount @employee_premium_amount
          end
          xml.family_premium_amount do
            xml.insurance_premium_amount @family_premium_amount
          end
        end
      end
    end
  end
end
