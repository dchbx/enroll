class EventException
  include Mongoid::Document
  include Mongoid::Timestamps

  field :time, type: Time

  validates :time, presence: true

  embedded_in :scheduled_event

  def time=(new_time)
    if new_time.blank?
      super(TimeKeeper.datetime_of_record)
    else
      super(Date.strptime(new_time, "%m/%d/%Y").to_date) rescue super(new_time.to_date) 
    end
  end
end