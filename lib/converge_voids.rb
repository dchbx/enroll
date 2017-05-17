class ConvergeVoids

  FILE_PATH= "#{Rails.root}/sample_xmls"

  def initialize(action)
    @action = action
  end

  def query_criteria
    { 
      :terminated_on => Date.new(2016,11,30), 
      :updated_at.gt => Date.new(2016,10,31), 
      :updated_at.lt => Date.new(2016,11,02),
      :kind => 'individual'
    }
  end

  def enrollment_csv_row(enrollment)
    [
      enrollment.subscriber.try(:hbx_id),
      enrollment.hbx_id,
      enrollment.kind,
      enrollment.coverage_kind,
      enrollment.plan.hios_id,
      format_date(enrollment.created_at),
      format_date(enrollment.updated_at),
      format_date(enrollment.effective_on),
      format_date(enrollment.terminated_on),
      enrollment.aasm_state.camelcase,
      enrollment.hbx_enrollment_members.size,
      enrollment.hbx_enrollment_members.map(&:hbx_id).join(',')
    ]
  end

  # Switch coverage
  def switch_and_void_hbx_ids(enrollments, terminated_enrollments)
    terminated_enrollments.inject([]) do |data, terminated_enrollment|
      if File.exist?("#{FILE_PATH}/#{terminated_enrollment.hbx_id}.xml") && exact_match = enrollments.detect{|en| (en <=> terminated_enrollment) == 0 }
        # TODO: Check about enrolled contingent
        if exact_match.coverage_selected?
          terminated_enrollment.update_attributes({aasm_state: 'coverage_selected', terminated_on: nil})
          exact_match.invalidate_enrollment!
        end

        data << exact_match
        data << terminated_enrollment
      else
        data
      end
    end
  end

  # Void non matching hbx_ids
  def void_hbx_ids(enrollments, terminated_enrollments)
    terminated_enrollments.inject([]) do |data, terminated_enrollment|
      terminated_enrollment.invalidate_enrollment!
      terminated_enrollment.update!(terminated_on: nil)
      data << terminated_enrollment
    end
  end

  def format_date(date)
    return '' if date.blank?
    date.strftime("%m/%d/%Y")
  end

  def process
    families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => query_criteria})

    count  = 0
    failed = 0
    CSV.open("converge_terminations_report_for_#{@action}.csv", "w") do |csv|
      csv << ['Primary HBX ID', 'Primary SSN', 'Primary DOB','Primary Last Name', 'Primary First Name', 'Subscriber HBX ID', 'Enrollment HBX ID', 'Market Kind', 'Coverge Kind', 'Enrollment HIOS ID', 'Created On', 'Updated On', 'Effective On', 'Terminated On', 'Current Status']

      families.each do |family|
        begin
          count += 1
          if count % 100 == 0
            puts "processed #{count}"
          end

          enrollments = family.active_household.hbx_enrollments.where({
            :kind => 'individual',
            :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES)
            }).order_by(:effective_on.desc).reject{|x| x.plan.active_year != 2016}

          terminated_enrollments = family.active_household.hbx_enrollments.where(query_criteria).order_by(:effective_on.desc).reject{|x| x.plan.active_year != 2016}

          enrollments_for_display = case @action
          when 'void'
            void_hbx_ids(enrollments, terminated_enrollments)
          when 'switch_and_void'
            switch_and_void_hbx_ids(enrollments, terminated_enrollments)
          end

          if enrollments_for_display.present?

            person = family.primary_applicant.person
            primary_details = [person.hbx_id, person.ssn, format_date(person.dob), person.first_name, person.last_name]

            enrollments_for_display.uniq.each do |enrollment|
              csv << (primary_details + enrollment_csv_row(enrollment))
            end
          end
        rescue Exception => e
          failed += 1
          puts "Failed.....#{e.to_s}"
        end
      end
    end

    puts count 
    puts failed
  end
end

