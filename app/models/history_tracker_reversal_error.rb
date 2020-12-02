class HistoryTrackerReversalError < StandardError
  attr_reader :history_track
  attr_reader :source_record

  def initialize(msg, history_track, source_record)
    super(msg)
    @history_track = history_track
    @source_record = source_record
  end
end