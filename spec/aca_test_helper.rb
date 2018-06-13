module AcaTestHelper
  def aca_state_abbreviation
    @aca_state_abbreviation ||= Settings.aca.state_abbreviation
  end

  def self.aca_state_abbreviation
    @aca_state_abbreviation ||= Settings.aca.state_abbreviation
  end
end
