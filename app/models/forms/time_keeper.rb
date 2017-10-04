module Forms
  class TimeKeeper
    include ActiveModel::Model
    include ActiveModel::Validations
    include Acapi::Notifiers

    delegate :date_of_record, :save, :valid?, to: :'::TimeKeeper'

    attr_reader :forms_date_of_record

    DATE_EVENT = "acapi.info.events.calendar.date_change"

    def date_of_record=(val)
      @forms_date_of_record = val
    end

    def set_date_of_record(date)
      notify(DATE_EVENT, {"current_date" => date})
    end

    def instance
      ::TimeKeeper.instance
    end
  end
end
