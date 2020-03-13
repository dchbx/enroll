# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'set_active_vlp_document')
describe SetActiveVlpDocument, dbclean: :after_each do
  let(:given_task_name) { 'set_active_vlp_document_id' }
  subject { SetActiveVlpDocument.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'migration' do
    let!(:consumer_role)  { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role).consumer_role }

    context 'for no valid vlp documents' do
      let(:vlp_doc) { FactoryBot.build(:vlp_document, subject: 'ajhssjah.png') }

      before do
        consumer_role.vlp_documents = [vlp_doc]
        consumer_role.save!
        subject.migrate
      end

      it 'should not update consumer_role' do
        expect(consumer_role.active_vlp_document_id).to be_nil
      end
    end

    context 'succesful migration' do
      let(:vlp_doc1) { FactoryBot.build(:vlp_document, updated_at: TimeKeeper.date_of_record) }
      let(:vlp_doc2) { FactoryBot.build(:vlp_document, :subject => 'Other (With I-94)', updated_at: (TimeKeeper.date_of_record + 1.day)) }

      before :each do
        consumer_role.vlp_documents = [vlp_doc1, vlp_doc2]
        consumer_role.save!
        subject.migrate
        @file = "#{Rails.root}/set_active_vlp_document_list.csv"
      end

      after :each do
        FileUtils.rm_rf("#{Rails.root}/set_active_vlp_document_list.csv")
      end

      it 'should set active_vlp_document_id on consumer_role' do
        consumer_role.reload
        expect(consumer_role.active_vlp_document_id).to eq(vlp_doc2.id)
      end

      it 'should add data to the file' do
        file_context = CSV.read(@file)
        expect(file_context.size).to be > 1
      end
    end
  end
end
