class ConvergeDataExport

  XML_FOLDER_PATH = "#{Rails.root}/LatestXmlFiles/ivl_final/"

  def initialize
  end

  def headers
    ['Enrollment HBX ID', 'Subscriber HBX ID','SSN', 'Last Name', 'First Name', 'HIOS_ID', 'Plan Name', 'Effective On', 'Terminated On']
  end

  def find_family_by_subscriber(enrollment)
    matched_people = match_person_instance(enrollment.family.primary_applicant.person)

    if matched_people.count > 1
      raise "Ambiguous person match"
    end

    if matched_people.blank?
      raise "Person Match not found"
    end

    if matched_people.first.families.size > 1
      raise "Ambiguous family match"
    end

    if matched_people.first.families.empty?
      raise "families not found"
    end

    matched_people.first.families.first
  end

  def export_renewal_missing_enrollments
    dentegra_id = CarrierProfile.all.detect{|x| x.legal_name == "Dentegra"}.id
    dentegra_hios_ids = Plan.where(carrier_profile_id: dentegra_id, active_year: 2016).map(&:hios_id)


    CSV.open("enrollments_active_in_edi_but_not_renewed.csv", "w") do |csv|
      csv << headers

      Dir.glob("#{XML_FOLDER_PATH}/*.xml").each do |file_path|
        begin
          individual_parser = Parsers::Xml::Cv::Importers::EnrollmentParser.new(File.read(file_path))
          enrollment = individual_parser.get_enrollment_object

          next if dentegra_hios_ids.include?(enrollment.plan.hios_id)

          canceled = false
          if enrollment.subscriber.coverage_end_on.present? && (enrollment.subscriber.coverage_start_on >= enrollment.subscriber.coverage_end_on)
            canceled = true 
          end

          next if (canceled || enrollment.terminated_on.present?)

          counter += 1

          match = HbxEnrollment.by_hbx_id(enrollment.hbx_id.to_s).first

          if match.blank?
            family = find_family_by_subscriber(enrollment)
          else
            family = match.family
          end

          renewals = family.active_household.hbx_enrollments.where({
            :kind => enrollment.kind,
            :aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES),
            :coverage_kind => enrollment.coverage_kind,
            :effective_on => Date.new(2017,1,1)
          }).reject{|en| en.subscriber.present? && enrollment.subscriber.present? && (en.subscriber.hbx_id != enrollment.subscriber.hbx_id)}

          next if renewals.present?
          csv << to_csv(enrollment)

          matched_count += 1
          if counter % 100 == 0
            puts "Processed #{counter}"
            puts "Matched #{matched_count} -- missing -- #{count}"
          end
        rescue Exception => e 
          puts "#{e.to_s}"
        end
      end
    end
  end

  def belongs_to_current_year?(enrollment)
    (TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year).cover?(enrollment.effective_on)
  end

  def export_active_ea_missing_termed_in_edi

    count = 0
    counter = 0
    CSV.open("active_ea_and_no_edi_coverage_exceptions.csv", "w") do |csv|

      csv << headers
      Dir.glob("#{Rails.root}/LatestXmlFiles/ivl_final/*.xml").each do |file_path|
          individual_parser = Parsers::Xml::Cv::Importers::EnrollmentParser.new(File.read(file_path))
          enrollment = individual_parser.get_enrollment_object
        begin

          next unless belongs_to_current_year?(enrollment)

          canceled = false
          if enrollment.subscriber.coverage_end_on.present? && (enrollment.subscriber.coverage_start_on >= enrollment.subscriber.coverage_end_on)
            canceled = true 
          end

          next unless (canceled || enrollment.terminated_on.present?)
          counter += 1

          match = HbxEnrollment.by_hbx_id(enrollment.hbx_id.to_s).first
          if match.blank?
            family = find_family_by_subscriber(enrollment)
          else
            family = match.family
          end

          matched_enrollments = family.active_household.hbx_enrollments.where({
            :kind => enrollment.kind,
            :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES),
            :coverage_kind => enrollment.coverage_kind
            }).order_by(:effective_on.asc)
          .select{|e| e.plan.active_year == enrollment.plan.active_year}
          .reject{|en| en.subscriber.present? && enrollment.subscriber.present? && (en.subscriber.hbx_id != enrollment.subscriber.hbx_id)}

          if matched_enrollments.present?
            count += 1
          end

          if counter % 100 == 0
            puts "Processed #{counter} Missing -- #{count}"
          end
        rescue Exception => e
          csv << (to_csv(enrollment) + [e.to_s])
        end
      end
    end
  end

  def export_ea_missing_enrollments
    count = 0
    counter = 0
    CSV.open("enrollments_edi_active_missing_in_EA.csv", "w") do |csv|

      csv << headers
      Dir.glob("#{Rails.root}/LatestXmlFiles/ivl_final/*.xml").each do |file_path|
          individual_parser = Parsers::Xml::Cv::Importers::EnrollmentParser.new(File.read(file_path))
          enrollment = individual_parser.get_enrollment_object
        begin
          counter += 1

          next unless belongs_to_current_year?(enrollment)

          canceled = false
          if enrollment.subscriber.coverage_end_on.present? && (enrollment.subscriber.coverage_start_on >= enrollment.subscriber.coverage_end_on)
            canceled = true 
          end

          next if (canceled || enrollment.terminated_on.present?)

          match = HbxEnrollment.by_hbx_id(enrollment.hbx_id.to_s).first
          if match.blank?
            family = find_family_by_subscriber(enrollment)
          else
            family = match.family
          end

          matched_enrollments = family.active_household.hbx_enrollments.where({
            :kind => enrollment.kind,
            :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES),
            :coverage_kind => enrollment.coverage_kind
            }).order_by(:effective_on.asc)
          .select{|e| e.plan.active_year == enrollment.plan.active_year}
          .reject{|en| en.subscriber.present? && enrollment.subscriber.present? && (en.subscriber.hbx_id != enrollment.subscriber.hbx_id)}

          active_coverage = matched_enrollments.detect{|e| HbxEnrollment::ENROLLED_STATUSES.include?(e.aasm_state)}
          
          if active_coverage.blank?
            csv << to_csv(enrollment)
            count += 1
          end

          if counter % 100 == 0
            puts "Processed #{counter} Missing -- #{count}"
          end
        rescue Exception => e 
          # csv << (to_csv(enrollment) + [e.to_s])
          # puts "#{e.to_s}"
        end
      end
    end
  end

  private

  def match_person_instance(person)
    @people_cache ||= {}
    return @people_cache[person.hbx_id] if @people_cache[person.hbx_id].present?

    if person.hbx_id.present?
      matched_people = ::Person.where(hbx_id: person.hbx_id)
    end

    if matched_people.blank?
      matched_people = ::Person.match_by_id_info(
        ssn: person.ssn,
        dob: person.dob,
        last_name: person.last_name,
        first_name: person.first_name
        )
    end

    @people_cache[person.hbx_id] = matched_people
    matched_people
  end

  def to_csv(enrollment)
    [
      enrollment.hbx_id,
      enrollment.subscriber.hbx_id,
      enrollment.subscriber.person.ssn,
      enrollment.subscriber.person.last_name,
      enrollment.subscriber.person.first_name,
      enrollment.plan.hios_id,
      enrollment.plan.name,
      enrollment.effective_on.strftime("%m/%d/%Y"),
      enrollment.terminated_on.present? ? enrollment.terminated_on.strftime("%m/%d/%Y") : ""]
    end
  end