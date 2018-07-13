module FederalHolidaysHelper

	def nth_wday(n, wday, month, year)
	t = Time.local year, month, 1
	first = t.wday
	if first == wday
	  fwd = 1
	elsif first < wday
	  fwd = wday - first + 1
	elsif first > wday
	  fwd = (wday+7) - first + 1
	end
	target = fwd + (n-1)*7
	begin
	  t2 = Time.local year, month, target
	rescue ArgumentError
	return nil
	end
	if t2.mday == target
	  t2
	else
	  nil
	end
	end

	def last_monday_may(year, month, day)
	date = Date.new(year, month, day)
	date - ( date.wday - 1 )
	end

	def schedule_time(time)
	if time.saturday?
	  return time.prev_month.end_of_month if time.day == 1
	  return time = time - 1.day
	end
	if time.sunday?
	  return time.next_month.beginning_of_month if time == time.end_of_month
	  return time = time  + 1.day
	end
	return time
	end
	
end  