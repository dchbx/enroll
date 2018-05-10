# require 'rails_helper'

# RSpec.describe ShopBrokerNotices::BrokerAgencyHiredNotice do
#   let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
#   let!(:employer_profile){ create :employer_profile}
#   let!(:broker_agency_profile) { create :broker_agency_profile }
#   let!(:broker_agency_account) { create :broker_agency_account }
#   let!(:person){ create :person }
#   let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
#   let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
#   let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
#   let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
#   let(:application_event){ double("ApplicationEventKind",{
#                             :name =>'Broker Agency Hired',
#                             :notice_template => 'notices/shop_broker_notices/broker_agency_hired_notice',
#                             :notice_builder => 'ShopBrokerNotices::BrokerAgencyHiredNotice',
#                             :event_name => 'broker_agency_hired',
#                             :mpi_indicator => 'SHOP_D047',
#                             :title => "You have been Hired as a Broker"})
#                           }
#     let(:valid_parmas) {{
#         :subject => application_event.title,
#         :mpi_indicator => application_event.mpi_indicator,
#         :event_name => application_event.event_name,
#         :template => application_event.notice_template
#     }}

#   describe "New" do
#     before do
#       allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
#       allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
#     end
#     context "valid params" do
#       it "should initialze" do
#         expect{ShopBrokerNotices::BrokerAgencyHiredNotice.new(employer_profile, valid_parmas)}.not_to raise_error
#       end
#     end

#     context "invalid params" do
#       [:mpi_indicator,:subject,:template].each do  |key|
#         it "should NOT initialze with out #{key}" do
#           valid_parmas.delete(key)
#           expect{ShopBrokerNotices::BrokerAgencyHiredNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
#         end
#       end
#     end
#   end

#   describe "Build" do
#     before do
#       allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
#       allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
#       allow(employer_profile).to receive_message_chain("broker_agency_accounts.detect").and_return(broker_agency_account)
#       @broker_notice = ShopBrokerNotices::BrokerAgencyHiredNotice.new(employer_profile, valid_parmas)
#       @broker_notice.build
#     end
#     it "should return employer name" do
#       expect(@broker_notice.notice.employer_name).to eq employer_profile.legal_name.titleize
#     end
#     it "should returm employer first name" do
#       expect(@broker_notice.notice.employer.employer_first_name).to eq employer_profile.staff_roles.first.first_name
#     end
#     it "should return employer last name" do
#       expect(@broker_notice.notice.employer.employer_last_name).to eq employer_profile.staff_roles.first.last_name
#     end
#     it "should return employer phone" do
#       expect(@broker_notice.notice.employer.employer_phone).to eq employer_profile.staff_roles.first.work_phone_or_best
#     end
#   end

#   describe "Rendering broker_agency_hired template" do
#     before do
#       allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
#       allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
#       allow(employer_profile).to receive_message_chain("broker_agency_accounts.detect").and_return(broker_agency_account)
#       @broker_notice = ShopBrokerNotices::BrokerAgencyHiredNotice.new(employer_profile, valid_parmas)
#     end

#     it "should render broker_agency_hired" do
#       expect(@broker_notice.template).to eq "notices/shop_broker_notices/broker_agency_hired_notice"
#     end

#     it "should generate pdf" do
#       @broker_notice.build
#       file = @broker_notice.generate_pdf_notice
#       expect(File.exist?(file.path)).to be true
#     end
#   end

# end
