module TimeHelper
  def time_remaining_in_words(user_created)
    last_day = user_created.to_date + 95.days
    days = (last_day.to_date - TimeKeeper.date_of_record.to_date).to_i
    pluralize(days, 'day')
  end

  def set_date_min_to_effective_on (enrollment, current_date)
    delta = (enrollment.effective_on - current_date).to_i + 1
    delta.to_s + 'D'
  end
end
