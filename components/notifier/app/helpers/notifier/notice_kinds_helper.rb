module Notifier
  module NoticeKindsHelper

    def date_of_notice
      TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def site_home_url
      Settings.site.home_url
    end

    def site_home_link
      link_to site_home_url, site_home_url
    end

    def site_short_name
      Settings.site.short_name
    end

    def employer_name
      'US Legal LLC'
    end

    def employer_staff_full_name
      'staff name'
    end

    def employer_address
    end

    def open_enrollment_begin
      'open enrollment begin date'
    end

    def open_enrollment_end
      'open enrollment end date'
    end

    def binder_due_date
      'due_date'
    end

    def broker_full_name
      'broker name'
    end

    def broker_agency_name
      'ageny name'
    end

    def broker_phone
      'broker phone'
    end

    def broker_email
      'broker_email'
    end

    def broker_present?
      false
    end

    def notice_template(notice_kind)
      notice_kind.template.raw_body.gsub('#{', '<%=').gsub('}','%>').gsub('[[', '<%').gsub(']]', '%>').html_safe
    end
  end
end