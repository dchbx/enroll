# frozen_string_literal: true

module StrippedNames
  def first_name=(val)
    write_attribute(:first_name, val.blank? ? nil : val.strip)
  end

  def middle_name=(val)
    write_attribute(:middle_name, val.blank? ? nil : val.strip)
  end

  def last_name=(val)
    write_attribute(:last_name, val.blank? ? nil : val.strip)
  end

  def name_sfx=(val)
    write_attribute(:name_sfx, val.blank? ? nil : val.strip)
  end
end
