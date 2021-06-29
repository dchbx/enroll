# frozen_string_literal: true

class EventException
  include Mongoid::Document
  include Mongoid::Timestamps

  field :time, type: Date

  validates :time, presence: true

  embedded_in :scheduled_event

  def time=(value)
    if value.blank?
      super(TimeKeeper.date_of_record)
    else
      begin
        super(Date.strptime(value, "%m/%d/%Y").to_date)
      rescue StandardError
        super(value.to_date)
      end
    end
  end
end