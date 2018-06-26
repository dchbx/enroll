require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delete_single_invoice_with_fein")

describe DeleteSingleInvoiceWithFein, dbclean: :after_each do
  let(:given_task_name) { "delete_single_invoice_with_fein" }
  subject { DeleteSingleInvoiceWithFein.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deletes the invoice" do
    let!(:organization) { FactoryGirl.create(:organization) }
    let!(:employer_profile) {FactoryGirl.create(:employer_profile, organization: organization)}
    let(:employer_invoice_1) {Document.new({ title: "file_name_1", date: TimeKeeper.date_of_record, creator: "hbx_staff", subject: "invoice", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
        format: "file_content_type" })}
    before do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      organization.documents << employer_invoice_1
      allow(ENV).to receive(:[]).with("date").and_return(organization.documents.first.date.to_s)
    end
    it "Should delete the invoice" do
      expect(organization.documents.size).to eq 1
      subject.migrate
      organization.reload
      expect(organization.documents.size).to eq 0
    end
  end
end

