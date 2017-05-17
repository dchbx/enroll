module Importers
  class ConversionEmployeeDelete < ConversionEmployeeCommon
    validate :delete_forbidden

    def delete_forbidden
      errors.add(:action, "delete actions are ignored")
    end

    def save
      return false unless valid?
    end
  end
end




