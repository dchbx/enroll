module Factories
  class FamilyTranscriptError < StandardError; end

  class FamilyTranscript

    def initialize
      @logger = Logger.new("#{Rails.root}/log/family_transcript_logfile.log")
    end

    ## Callbacks
    # TODO: determine needs for callbacks
    # before_create
    # before_update :update_person

    # Expect family_transcript is a hash structured after CV2?
    def process_transcript(family_transcript = {})
      return family_transcript_prototype if family_transcript.blank?

      local_people = family_transcript[:people].reduce([]) { |person| process_person(person) }

      # Syntactic check
      if local_people.detect { |processed_person| processed_person.errors.count > 0 }
        #     with_logging('save', local_people) { |instance | instance.save }
      end

      # TODO: Compare the locally found records against the transcript values

      # TODO: Eligibility/Functional checks, e.g. Citizenship and VLP
      # TODO: Any need to create User object for each person with respective roles?

      # TODO: Once all is clear with the people, they must be persisted to construct the family

      local_people.each { |person| person.save }

      # TODO: identify primary_family_member
      local_family = find_or_build_family(local_people)

      local_family_enrollments = family_transcript.households.each do |household|
        household.hbx_enrollments.each { |hbx_enrollment|  find_or_build_hbx_enrollment(hbx_enrollment, family_transcript.family) }
      end

      { family: family.local_family({
            family_members: [local_family.family_members],
            irs_groups: [local_family.irs_groups],
            households: [local_family.households({
                            hbx_enrollments: [local_family_enrollments]
                          })
                      ]
          }),
        people: [local_people]
      }
    end

    def process_people(transcript_people)
      local_people = transcript_people.reduce([]) { |list, person| list << find_or_build_person(person) }
      invalid_people = local_people.reduce([]) { |list, person| list << { id: person.id, errors: person.errors } if person.is_valid? == false }
      { people: local_people, errors: invalid_people }
    end

    def audit_family(family_transcript)
      local_family = find_or_build_local(family_transcript)

    end

    def find_or_build_person(transcript_person)
      builder = Factories::TranscriptTypes::Person.new
      builder.find_or_build(transcript_person)
      person_transcript = builder.transcript

      # Support citizenship and VLP status override?  Use Ruleset?
    end

    def find_or_build_family(transcript_primary_member)

    end

    def build_consumer_role(transcript_consumer)
      # Support citizenship and VLP status override
    end

    def build_employee_role(transcript_employee, transcript_employer)
    end

    def find_or_build_hbx_enrollment(transcript_family, transcript_hbx_enrollment)
      enrollment = match_hbx_enrollment(hbx_enrollment)

      make_employer_sponsored_enrollment
      make_individual_enrollment
    end

  private

    def match_family(family)
    end

    def match_person(transcript_person)
      Person.match_existing_person(transcript_person)
    end

    def match_hbx_enrollment(hbx_enrollment)

    end

    # This code pulled from Interactors::FindOfCreateInsuredPerson
    def update_person
      # person = people.first
      # user.save if user
      # person.user = user if user
      # if person.ssn.nil?
      #   #matched on last_name and dob
      #   person.ssn = context.ssn
      #   person.gender = context.gender
      # end
      # person.save
      # user = person.user if context.role_type == User::ROLES[:consumer]
      # person, is_new = person, false
    end


    def with_logging(description, the_object)
      begin
        @logger.debug("Starting #{description}")
        yield(the_object)
        @logger.debug("Completed #{description}")
      rescue
        @logger.error("#{description} failed!!")
        raise
      end
    end


  end
end
