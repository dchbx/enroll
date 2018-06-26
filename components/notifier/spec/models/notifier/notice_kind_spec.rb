require 'rails_helper'

module Notifier
  RSpec.describe NoticeKind, type: :model do
    

    describe '.set_data_elements' do

      subject { Notifier::NoticeKind.new }

      let!(:template) { subject.build_template }

      before do
        allow(subject).to receive(:tokens).and_return(["employer_profile.account_number", "employer_profile.invoice_number", "employer_profile.invoice_date", "employer_profile.coverage_month", "employer_profile.total_amount_due", "employer_profile.date_due", "employer_profile.first_name", "employer_profile.last_name", "address.street_1", "address.street_2", "address.city", "address.state", "address.zip", "site_short_name", "site_invoice_bill_url", "contact_center_mailing_address_name", "contact_center_address_one", "contact_center_city", "contact_center_state", "contact_center_postal_code", "contact_center_tty_number", "employer_profile.first_name", "employer_profile.last_name", "employer_profile.coverage_month", "offered_product.plan_name", "offered_product.covered_subscribers", "offered_product.covered_dependents", "offered_product.total_charges", "employer_profile.total_amount_due", "enrollment.subscriber.last_name", "enrollment.subscriber.first_name", "enrollment.number_of_enrolled", "enrollment.employer_cost", "enrollment.employee_cost", "enrollment.premium"])
        allow(subject).to receive(:conditional_tokens).and_return(["employer_profile.addresses.each do | address |", "employer_profile.offered_products.each do | offered_product |", "offered_product.enrollments.each do | enrollment |"])
      end

      it "should parse data elements for the template" do 
        subject.set_data_elements
        expect(template.data_elements).to be_present
        expect(template.data_elements).to eq ([
            "employer_profile.account_number",
            "employer_profile.invoice_number",
            "employer_profile.invoice_date",
            "employer_profile.coverage_month",
            "employer_profile.total_amount_due",
            "employer_profile.date_due",
            "employer_profile.first_name",
            "employer_profile.last_name",
            "site_short_name",
            "site_invoice_bill_url",
            "contact_center_mailing_address_name",
            "contact_center_address_one",
            "contact_center_city",
            "contact_center_state",
            "contact_center_postal_code",
            "contact_center_tty_number",
            "employer_profile.first_name",
            "employer_profile.last_name",
            "employer_profile.coverage_month",
            "employer_profile.total_amount_due",
            "employer_profile.addresses",
            "employer_profile.offered_products",
            "offered_product.enrollments"
          ])
      end
    end
  end
end
