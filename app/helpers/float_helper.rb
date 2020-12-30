# frozen_string_literal: true

module FloatHelper
  def float_fix(float_number)
    BigDecimal((float_number).to_s).round(8).to_f
  end

  def round_down_float_two_decimals(float_number)
    BigDecimal((float_number).to_s).round(8).round(2, BigDecimal::ROUND_DOWN).to_f
  end
end
