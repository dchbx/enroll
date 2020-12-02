module HistoryTrackerToRecord
  extend ActiveSupport::Concern

  ACTION_ORDER = {
    "create" => 1,
    "update" => 5,
    "destroy"  => 10
  }

  def filtered_history_tracks
    self.history_tracks.reject do |ht|
      last_chain_name = ht.association_chain.last["name"]
      ((ht.created_at.to_f - self.created_at.to_f).abs < 1.1) ||
        ::Person::IVL_ELIGIBILITY_EXCLUDED_CHAINS.include?(last_chain_name)
    end
  end

  def reversed_history_tracks(ht_date)
    all_tracks = self.history_tracks.to_a.sort do |a,b|
      sort_history_tracks(a,b)
    end
    tracks_to_reverse = all_tracks.reject do |ht|
      last_chain_name = ht.association_chain.last["name"]
      (ht.created_at <= ht_date) || ((ht.created_at.to_f - self.created_at.to_f).abs < 1.1) ||
        ::Person::IVL_ELIGIBILITY_EXCLUDED_CHAINS.include?(last_chain_name)
    end.reverse
  end

  def sort_history_tracks(a,b)
    a_id = a.association_chain.last["id"].to_s
    b_id = b.association_chain.last["id"].to_s
    a_action = a.action.to_s
    b_action = b.action.to_s
    return (a.created_at <=> b.created_at) if a_id != b_id
    return (a.created_at <=> b.created_at) if a_action == b_action
    ACTION_ORDER[a_action] <=> ACTION_ORDER[b_action]
  end

  def history_tracker_to_record(ht_date)
    # Example: If is a HistoryTracker in person model
    # history_track.trackable will return consumer_role
    # if the consumer_role was modified. trackable_root
    # will return person for both
    all_tracks = self.history_tracks.to_a.sort do |a,b|
      sort_history_tracks(a,b)
    end
    tracks_to_reverse = reversed_history_tracks(ht_date)
    tracks_to_reverse.each do |rt|
      begin
      if rt.association_chain.length < 2
        self.attributes = rt.undo_attr(nil)
      else
        case rt.action
        when "create"
          association_chain_without_last = rt.association_chain[1..-2]
          last_in_chain = rt.association_chain.last
          chain_target = association_chain_without_last.inject(self) do |acc, chain_location|
            if acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).detect do |ao|
                ao.id.to_s == chain_location["id"].to_s
              end
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          if chain_target.send(last_in_chain["name"]).is_a?(Enumerable)
            remaining_items = chain_target.send(last_in_chain["name"].to_sym).reject do |record|
              record.id.to_s == last_in_chain["id"].to_s
            end
            chain_target.send((last_in_chain["name"] + "=").to_sym, remaining_items)
          else
            chain_target.send((last_in_chain["name"] + "=").to_sym, nil)
          end
        when "destroy"
          association_chain_without_last = rt.association_chain[1..-2]
          last_in_chain = rt.association_chain.last
          chain_target = association_chain_without_last.inject(self) do |acc, chain_location|
            if acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).detect do |ao|
                ao.id.to_s == chain_location["id"].to_s
              end
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          if chain_target.send(last_in_chain["name"]).is_a?(Enumerable)
            chain_target.send(last_in_chain["name"].to_sym).build(rt.original.merge({:id  => last_in_chain["id"]}))
          else
            chain_target.send(("build_" + last_in_chain["name"]).to_sym, rt.original.merge({:id  => last_in_chain["id"]}))
          end
        else
          association_chain_without_first = rt.association_chain[1..-1]
          chain_target = association_chain_without_first.inject(self) do |acc, chain_location|
            if acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).detect do |ao|
                ao.id.to_s == chain_location["id"].to_s
              end || acc.send(chain_location["name"].to_sym).build
            else # embeds_one
              acc.send(chain_location["name"].to_sym) || acc.send("build_#{chain_location["name"]}".to_sym)
            end
          end
          chain_target.attributes = rt.original
        end
      end
      rescue Exception => e
        log_string = e.inspect + " - ASSOCIATION CHAIN:" + rt.association_chain.inspect + " - HISTORY TRACK: " + rt.inspect + " - PERSON: " + self.inspect
        Rails.logger.error("[IVL ELIG AUDIT]") { log_string }
        raise HistoryTrackerReversalError.new(e.message, rt, self)
      end
    end

    self
  end
end
