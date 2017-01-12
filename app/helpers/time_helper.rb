module TimeHelper
  def time_remaining_in_words(user_created)
    last_day = user_created.to_date + 95.days
    days = (last_day.to_date - TimeKeeper.date_of_record.to_date).to_i
    pluralize(days, 'day')
  end

  def set_date_min_to_effective_on (enrollment)
    enrollment.effective_on + 1.day
  end

  def set_date_max_to_plan_end_of_year (enrollment)
    year = enrollment.effective_on.year
    final_day = Date.new(year, 12, 31)
  end
end
