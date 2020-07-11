QualifyingLifeEventKind.where(is_active: true).each do |qle|
  qle.update_attributes(aasm_state: :active)
end

