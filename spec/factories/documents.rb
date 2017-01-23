FactoryGirl.define do
  factory :document do

    factory :tax_document, class: TaxDocument do
      subject "1095A"
      version_type "new"
      hbx_enrollment_id "100000"
      year "2016"
    end
  end
end
