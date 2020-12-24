# frozen_string_literal: true

# During Preview (view) we have all the identifiers (record ids) we want process
# When Submitting Preview, we capture all

module Admin
  # Stores information about admin bulk notice
  class BulkNotice
    include Mongoid::Document
    include Mongoid::Timestamps

    include AASM

    field :user_id, type: String
    field :audience_type, type: String
    field :audience_ids, type: Array
    field :subject, type: String
    field :body, type: String
    field :aasm_state, type: String
    field :document_metadata, type: Hash
    field :sent_at, type: DateTime

    belongs_to :user, class_name: 'User'

    embeds_many :results, class_name: "Admin::BulkNoticeResult"
    embeds_many :documents, as: :documentable, class_name: "Document"

    accepts_nested_attributes_for :documents, allow_destroy: true

    def send_notices!
      audience_ids.map do |audience_id|
        BulkNoticeWorker.perform_async(audience_id, self.id)
      end
      assign_attributes sent_at: TimeKeeper.datetime_of_record
      complete!
      save
    end

    def on_success(_status, _options)
      complete!
    end

    aasm do
      state :draft, initial: true
      state :processing, after_enter: :send_notices!
      state :completed
      state :failure

      event :process do
        transitions from: :draft, to: :processing
      end

      event :complete do
        transitions from: :processing, to: :completed
      end
    end

    def upload_document(params, user)
      ::Operations::Documents::Upload.new.call(resource: self, file_params: params, user: user, subjects: subjects)
    end

    def subjects
      audience_ids.map {|identifier| {id: identifier, type: audience_type}}
    end

    def audience_identifiers; end
  end
end
