require 'rails_helper'

class DummyNoticeKind
  attr_accessor :title, :event_name, :resource, :market_kind, :notice_number, :notice_path
  include Notifier::NoticeBuilder

  def initialize(params)
    self.event_name = params[:event_name]
    self.title = params[:title]
    self.market_kind = params[:market_kind]
    self.notice_number = params[:notice_number]
  end

  def shop_market?; end
end

module Notifier
  module NoticeBuilder
    RSpec.describe NoticeBuilder, dbclean: :around_each do
      let(:hbx_id) { "1234" }
      let(:event_name) {"acapi.info.events.notices.notice"}
      let(:payload) do
        {
          "employer_id" => hbx_id,
          "event_object_kind" => "EventObjectKind",
          "event_object_id" => "12345"
        }
      end
      let(:subject) do
        DummyNoticeKind.new(event_name: event_name, title: 'Test', notice_number: "ABC_123")
      end

      describe ".store_paper_notice" do
        let(:bucket_name) { 'paper-notices' }
        let(:notice_filename_for_paper_notice) { "#{hbx_id}_#{subject.title}_#{subject.notice_number.delete('_')}_#{subject.notice_type}.pdf" }
        let(:doc_uri) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}#sample-key" }
        let(:notice_path_for_paper_notice) { Rails.root.join("tmp", notice_filename_for_paper_notice) }

        before do
          allow(FileUtils).to receive(:cp)
          allow(File).to receive(:delete)
          allow(subject).to receive(:resource).and_return(resource)
          allow(subject).to receive(:notice_path).and_return("notice_path")
          allow(Aws::S3Storage).to receive(:save).and_return(doc_uri)
        end

        context "ivl_market" do
          let(:resource) { ConsumerRole.new }

          it 'should store paper notices for person with paper contact method' do
            allow(resource).to receive(:person).and_return(double(hbx_id: '1234'))
            allow(resource).to receive(:can_receive_paper_communication?).and_return(true)
            allow(subject).to receive(:shop_market?).and_return(false)
            subject.store_paper_notice
            expect(notice_filename_for_paper_notice).to include("IVL")
            expect(Aws::S3Storage).to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
          end

          it 'should not store paper notices for person with electronic communication contact method' do
            allow(resource).to receive(:person).and_return(double(hbx_id: '1234'))
            allow(resource).to receive(:can_receive_paper_communication?).and_return(false)
            allow(subject).to receive(:shop_market?).and_return(false)
            subject.store_paper_notice
            expect(notice_filename_for_paper_notice).to include("IVL")
            expect(Aws::S3Storage).not_to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
          end
        end

        context 'shop_market' do
          context 'Notices for Employee' do

            let(:resource) { EmployeeRole.new }

            if ::Settings.notices.shop.store_paper_notice
              it 'should store paper notices for Employee with paper contact method' do
                allow(resource).to receive(:person).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(true)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(Aws::S3Storage).to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end

              it 'should store paper notices for Employee with electronic communication contact method' do
                allow(resource).to receive(:person).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(true)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(Aws::S3Storage).to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end
            else
              it 'should not store paper notices for Employee with paper contact method' do
                allow(resource).to receive(:person).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(true)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(notice_filename_for_paper_notice).to include("EE")
                expect(Aws::S3Storage).not_to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end

              it 'should not store paper notices for Employee with electronic communication contact method' do
                allow(resource).to receive(:person).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(false)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(notice_filename_for_paper_notice).to include("EE")
                expect(Aws::S3Storage).not_to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end
            end
          end

          context 'Notices for Employer' do

            let(:resource) { BenefitSponsors::Organizations::AcaShopDcEmployerProfile.new }

            if ::Settings.notices.shop.store_paper_notice
              it 'should store paper notices for Employer with paper contact method' do
                allow(resource).to receive(:organization).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(true)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(Aws::S3Storage).to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end

              it 'should store paper notices for Employer with electronic communication contact method' do
                allow(resource).to receive(:organization).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(true)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(Aws::S3Storage).to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end
            else
              it 'should not store paper notices for Employer with paper contact method' do
                allow(resource).to receive(:organization).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(true)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(notice_filename_for_paper_notice).to include("ER")
                expect(Aws::S3Storage).not_to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end

              it 'should not store paper notices for Employer with electronic communication contact method' do
                allow(resource).to receive(:organization).and_return(double(hbx_id: '1234'))
                allow(resource).to receive(:can_receive_paper_communication?).and_return(false)
                allow(subject).to receive(:shop_market?).and_return(true)
                subject.store_paper_notice
                expect(notice_filename_for_paper_notice).to include("ER")
                expect(Aws::S3Storage).not_to have_received(:save).with(notice_path_for_paper_notice, bucket_name, notice_filename_for_paper_notice)
              end
            end
          end
        end
      end

      describe ".send_generic_notice_alert" do
        let(:usermailer) {double "UserMailer"}

        before do
          allow(subject).to receive(:is_employer?).and_return(false)
          allow(UserMailer).to receive(:generic_notice_alert).and_return(usermailer)
          allow(usermailer).to receive(:deliver_now).and_return(true)
          subject.send_generic_notice_alert
        end

        it "should receive send_generic_notice_alert" do
          expect(UserMailer).to have_received(:generic_notice_alert)
        end
      end

      describe 'inserts' do

        context 'for IVL inserts' do

          before do
            allow(subject).to receive(:notice_path).and_return('tt_notice_path')
            allow(subject).to receive(:join_pdfs).and_return(true)
          end

          context 'ivl_non_discrimination' do
            it {expect(subject.ivl_non_discrimination).to be_truthy}
          end

          context 'ivl_taglines' do
            it {expect(subject.ivl_taglines).to be_truthy}
          end

          context 'ivl_attach_envelope' do
            it {expect(subject.ivl_attach_envelope).to be_truthy}
          end

          after do
            File.delete('tt_notice_path') if File.exist?('tt_notice_path')
          end
        end
      end
    end
  end
end
