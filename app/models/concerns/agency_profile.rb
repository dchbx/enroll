# frozen_string_literal: true

module AgencyProfile
  extend ActiveSupport::Concern

  included do
    # has_many employers
    def employer_clients
      return unless (GeneralAgencyProfile::MARKET_KINDS - ["individual"]).include?(market_kind)
      return @employer_clients if defined? @employer_clients
      @employer_clients = EmployerProfile.public_send("find_by_#{self.class.to_s.underscore}".to_sym, self)
    end

    # TODO: has_many families
    def family_clients
      return unless (GeneralAgencyProfile::MARKET_KINDS - ["shop"]).include?(market_kind)
      return @family_clients if defined? @family_clients
      @family_clients = Family.public_send("by_#{self.class.to_s.underscore}_id".to_sym, self.id)
    end
  end
end
