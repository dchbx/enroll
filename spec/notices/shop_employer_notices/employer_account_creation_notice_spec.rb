require 'rails_helper'

RSpec.describe ShopEmployerNotices::EmployerAccountCreationNotice, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let(:person){ create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Welcome to DC Health Link',
                            :notice_template => 'notices/shop_employer_notices/employer_account_creation_notice',
                            :notice_builder => 'ShopEmployerNotices::EmployerAccountCreationNotice',
                            :event_name => 'employer_account_creation_notice',
                            :mpi_indicator => 'SHOP_D001',
                            :title => "Welcome Notice to Employer"})
                          }

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerAccountCreationNotice.new(employer_profile, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployerAccountCreationNotice.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployerAccountCreationNotice.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerAccountCreationNotice.new(employer_profile, valid_params)
    end
    it "should build notice with all necessory information" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "Rendering notice template and generate pdf" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerAccountCreationNotice.new(employer_profile, valid_params)
    end
    it "should render notice" do
      expect(@employer_notice.template).to eq "notices/shop_employer_notices/employer_account_creation_notice"
    end
    it "should generate pdf" do
      @employer_notice.append_hbe
      @employer_notice.build
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
