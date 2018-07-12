require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "migrate_invoices_to_employer_profile")

describe MigrateInvoicesToEmployerProfile do

  let(:given_task_name) { "migrate_invoices_to_employer_profile" }
  subject { MigrateInvoicesToEmployerProfile.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "migrate invoices from organization to employer_profile", dbclean: :after_each do
    let(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let(:organization) { org = FactoryGirl.create(:organization, employer_profile:employer_profile)
                         org.documents << Document.new(subject: "invoice")
                         org
                       }

    context "should find documents on organization with subject as invoice" do
      it "move invoices to employer_profile" do
        expect(organization.documents.size).to eq 1
        expect(organization.documents.first.subject).to eq "invoice"
        subject.migrate
        organization.reload
        expect(organization.documents.size).to eq 0
      end
    end
  end
end