module DataTablesFilters

  def set_filter
    if params[:filter].present?
      filter = params[:filter]
    end
  end

  module EmployerInvoicesIndexFilters
    def filter_employers(employers, filter)
      if filter.present?
        case filter
        when "InitialFirstMonthFilter"
          employers = Organization.employer_profile_renewing_starting_on(TimeKeeper.date_of_record.next_month.beginning_of_month)
        when "InitialSecondMonthFilter"
          employers = Organization.employer_profile_renewing_starting_on(TimeKeeper.date_of_record.next_month.beginning_of_month.next_month)
        when "InitialThirdMonthFilter"
          employers = Organization.employer_profile_renewing_starting_on(TimeKeeper.date_of_record.next_month.beginning_of_month.next_month.next_month)
        when "RenewingFirstMonthFilter"
          employers = Organization.employer_profile_renewing_starting_on(TimeKeeper.date_of_record.next_month.beginning_of_month)
        when "RenewingSecondMonthFilter"
          employers = Organization.employer_profile_renewing_starting_on(TimeKeeper.date_of_record.next_month.beginning_of_month.next_month)
        when "RenewingThirdMonthFilter"
          employers = Organization.employer_profile_renewing_starting_on(TimeKeeper.date_of_record.next_month.beginning_of_month.next_month.next_month)
        end

        return employers

      end
    end
  end

end
