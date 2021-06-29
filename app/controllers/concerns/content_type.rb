# frozen_string_literal: true

module ContentType
  def csv_content_type
    case request.user_agent
    when /windows/i
      'application/vnd.ms-excel'
    else
      'text/csv'
    end
  end
end
