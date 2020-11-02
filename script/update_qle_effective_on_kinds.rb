# Script to update qle effective on kind. retiring exact_date kind to  date_of_event.
# updating first_of_next_month effective on kind.

QualifyingLifeEventKind.where(:effective_on_kinds.in=> ['exact_date']).each do |qle|
  qle.update_attributes(effective_on_kinds: qle.effective_on_kinds.map{|kind| kind == "exact_date" ? "date_of_event": kind})
end

QualifyingLifeEventKind.where(:effective_on_kinds.in=> ['first_of_next_month'], :market_kind.in => ['shop', 'fehb']).each do |qle|
  qle.update_attributes(effective_on_kinds: qle.effective_on_kinds.map{|kind| kind == "first_of_next_month" ? "first_of_next_month_coinciding": kind})
end

QualifyingLifeEventKind.where(:effective_on_kinds.in=> ['first_of_next_month'], market_kind: 'individual').each do |qle|
  qle.update_attributes(effective_on_kinds: qle.effective_on_kinds.map{|kind| kind == "first_of_next_month" ? "first_of_next_month_plan_selection": kind})
end