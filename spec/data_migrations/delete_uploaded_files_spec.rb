# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'delete_uploaded_files')

describe DeleteUploadedFiles, dbclean: :after_each do
  let(:given_task_name) { 'delete_uploaded_files' }
  subject { DeleteUploadedFiles.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migration' do
    let!(:consumer_role)  { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role).consumer_role }
    let(:vlp_doc2) { FactoryBot.build(:vlp_document, :subject => 'Other (With I-94)', updated_at: (TimeKeeper.date_of_record + 1.day)) }

    context 'succesful migration' do
      let(:vlp_doc1) { FactoryBot.build(:vlp_document, subject: 'ajhssjah.png', verification_type: 'Citizenship', identifier: 'bucket-123') }

      before :each do
        consumer_role.vlp_documents = [vlp_doc1, vlp_doc2]
        consumer_role.save!
        subject.migrate
        @file = "#{Rails.root}/list_of_people_uploaded_files_deleted.csv"
      end

      after :each do
        FileUtils.rm_rf("#{Rails.root}/list_of_people_uploaded_files_deleted.csv")
      end

      it "should delete all vlp_documents(uploaded files) under consumer_role" do
        consumer_role.reload
        expect(consumer_role.vlp_documents.count).to eq(1)
      end

      it 'should add data to the file' do
        file_context = CSV.read(@file)
        expect(file_context.size).to be > 1
      end
    end

    context 'for no valid vlp documents for deletion' do
      let(:vlp_doc1) { FactoryBot.build(:vlp_document, updated_at: TimeKeeper.date_of_record) }

      context 'with vlp documents' do
        before do
          consumer_role.vlp_documents = [vlp_doc1, vlp_doc2]
          consumer_role.vlp_documents.each {|doc| doc.save! }
          consumer_role.save!
          subject.migrate
        end

        it 'should not delete any vlp_documents under consumer_role' do
          expect(consumer_role.vlp_documents.count).to eq(2)
        end
      end

      context 'without any vlp documents' do
        before do
          consumer_role.vlp_documents = []
          consumer_role.save!
        end

        it 'should do not raise any error' do
          expect{subject.migrate}.not_to raise_error
        end
      end
    end
  end
end
