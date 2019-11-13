module HistoryTrackerToRecord
  extend ActiveSupport::Concern

  # trackable_class should be capitalized as string like "Person"
  def history_tracker_to_record(history_tracker, trackable_class)
    # Example: If is a HistoryTracker in person model
    # history_track.trackable will return consumer_role
    # if the consumer_role was modified. trackable_root
    # will return person for both
    trackable_record = history_tracker.trackable_root
    # Example structure of modified: {"is_state_resident"=>false}
    modified_attributes = history_tracker.modified
    last_association = history_tracker.association_chain.last
    modified_attributes.each do |key, value|
      if last_association["name"] == trackable_class
        # Changes bottom level document
        trackable_record[key] = value
      elsif trackable_record.send(last_association["name"]).is_a?(Enumerable)
        # embeds_many or has_many, needs id, hence checking if enumerable type object like array
        last_association_id = last_association["id"].to_s
        trackable_record.send(last_association["name"]).find(last_association_id)[key] = value
      else
        # embeds_one type relationship
        trackable_record.send(last_association["name"])[key] = value
      end
    end
    trackable_record
  end
end
