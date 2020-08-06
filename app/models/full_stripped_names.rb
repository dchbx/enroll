# frozen_string_literal: true

module FullStrippedNames
  include StrippedNames

  def name_pfx=(val)
    write_attribute(:name_pfx, val.blank? ? nil : val.strip)
  end
end
