# This code was exctracted from insured/families_controller.rb#check_qle_date,
# a method which is in itself called from 
# from qle.js.erb
class CustomQleDateValidator
  def initialize(qle_id, qle_date, qle_reason_val_string, person_id)
    @qle = QualifyingLifeEventKind.where(id: qle_id).first
    @qle_date = Date.strptime(qle_date, "%m/%d/%Y")
    @person = Person.where(id: person_id).first
    @qle_reason_val = qle_reason_val_string
    @today = TimeKeeper.date_of_record
    @start_date = @today - 30.days
    @end_date = @today + 30.days
    check_qle_date
    trigger_notice_observers
  end

  def qle_date_qualifies?
    @qualified_date
  end

  def check_qle_date
    if @qle.present?
      if @qle.post_event_sep_in_days > 0
        @start_date = @today - @qle.post_event_sep_in_days.try(:days)
      end
      if @qle.pre_event_sep_in_days > 0
        @end_date = @today + @qle.pre_event_sep_in_days.try(:days)
      end
      @effective_on_options = @qle.employee_gaining_medicare(@qle_date) if @qle.is_dependent_loss_of_coverage?
      @qle_reason_val = @qle_reason_val if @qle_reason_val.present?
      @qle_end_on = @qle_date + @qle.post_event_sep_in_days.try(:days)
    end
    # The return of this boolean is the primary determinent for enrollment eligibility
    # By default, the eligibility will be determined by whether or not the user's QLE date
    # was 30 days before or on today's date, or 30 days. Otherwise, the eligibility will take into consideration the
    # pre and post event sep in days, setting the start date for the QLE as being Today - the QLE's post event sep in days and
    # end date being Today + the QLE's pre event sep in days
    @qualified_date = (@start_date <= @qle_date && @qle_date <= @end_date) ? true : false
  end

  def trigger_notice_observers
    if ((@qle.present? && @qle.shop?) && !@qualified_date && @qle.present?)
      benefit_application = @person.active_employee_roles.first.employer_profile.active_benefit_application
      reporting_deadline = @qle_date > @today ? @today : @qle_date + 30.days
      employee_role = @person.active_employee_roles.first
      if Settings.site.key == :cca
        trigger_notice_observer(
          employee_role,
          benefit_application,
          'employee_notice_for_sep_denial',
          qle_title: @qle.title, qle_reporting_deadline: reporting_deadline.strftime("%m/%d/%Y"),
          qle_event_on: @qle_date.strftime("%m/%d/%Y")
        )
      elsif Settings.site.key == :dc
        event_name = @person.has_multiple_active_employers? ? 'sep_denial_notice_for_ee_active_on_multiple_rosters' : 'sep_denial_notice_for_ee_active_on_single_roster'
        trigger_notice_observer(
          employee_role,
          benefit_application,
          event_name,
          qle_title: @qle.title,
          qle_reporting_deadline: reporting_deadline.strftime("%m/%d/%Y"),
          qle_event_on: @qle_date.strftime("%m/%d/%Y")
        )
      end
    end
  end
end
