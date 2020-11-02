# frozen_string_literal: true

class HistoryActionTracker
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :history_trackable, polymorphic: true


  field :actor, type: String #modifier: consumer, admin, hub response, etc
  field :action, type: String #action causing the changes
  field :history_tracker_id, type: String #mongoid-history HistoryTracker record
  field :tracked_collection, type: String
  field :details, type: String #to store helpful details(instructions) to render etc


  def tracking_record
    HistoryTracker.find(history_tracker_id)
  end

  def modified_attributes
    tracking_record.modified
  end
end
