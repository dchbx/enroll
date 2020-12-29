# frozen_string_literal: true

module Operations
  module People
    module Roles
      # Persist Staff operation is to persist employer staff with ability for self coverage
      # This will return an entity, which we use in our ERB files.
      class PersistStaff
        include Dry::Monads[:result, :do, :try]


        def call(params)
          params = yield validate_params(params)
          @profile = yield fetch_profile(params[:profile_id])
          @person = yield fetch_person(params[:person_id])
          yield check_existing_staff
          result = yield persist(params[:coverage_record])

          Success(result)
        end

        private

        def validate_params(params)
          result = Validators::StaffContract.new.call(params)
          if result.success?
            Success(result.to_h)
          else
            Failure(result.errors.to_h)
          end
        end

        def fetch_profile(id)
          result = Try do
            profile = BenefitSponsors::Organizations::Profile.find(id)

            if profile
              Success(profile)
            else
              Failure({:message => 'Profile not found'})
            end
          end
          result.to_result.failure? ? Failure({:message => 'Profile not found'}) : result.to_result.value!
        end

        def fetch_person(id)
          person = Person.where(id: id).first

          if person
            Success(person)
          else
            Failure({:message => 'Person not found'})
          end
        end

        def check_existing_staff
          if is_dc_employer_profile?
            check_employer_staff_role
          elsif is_broker_profile?
            check_broker_staff_role
          elsif is_general_profile?
            check_general_agency_staff_role
          end
        end

        def check_employer_staff_role
          if @person.employer_staff_roles.where(:aasm_state.ne => :is_closed).map(&:benefit_sponsor_employer_profile_id).map(&:to_s).include? @profile.id.to_s
            Failure({:message => 'Already staff role exists for the selected organization'})
          else
            Success({})
          end
        end

        def check_broker_staff_role
          if @person.broker_agency_staff_roles.where(:aasm_state.ne => "broker_agency_terminated").map(&:benefit_sponsors_broker_agency_profile_id).map(&:to_s).include? @profile.id.to_s
            Failure({:message => 'Already staff role exists for the selected organization'})
          else
            Success({})
          end
        end

        def check_general_agency_staff_role
          if @person.general_agency_staff_roles.where(:aasm_state.ne => "general_agency_terminated").map(&:benefit_sponsors_general_agency_profile_id).map(&:to_s).include? @profile.id.to_s
            Failure({:message => 'Already staff role exists for the selected organization'})
          else
            Success({})
          end
        end

        def persist(params)
          result = if is_dc_employer_profile?
                     persist_employer_staff(params)
                   elsif is_broker_profile?
                     persist_broker_staff
                   elsif is_general_profile?
                     persist_general_agency_staff
                   end

          result.to_result.failure? ? Failure({:message => 'Failed to create records, contact HBX Admin'}) : result.to_result.value!
        end

        def persist_employer_staff(params)
          Try do
            address = params[:address]
            email = params[:email]
            coverage_record = CoverageRecord.new(
              ssn: params[:ssn],
              dob: params[:dob],
              hired_on: params[:hired_on],
              is_applying_coverage: params[:is_applying_coverage],
              gender: params[:gender],
              address: Address.new({kind: address[:kind],
                                    address_1: address[:kind],
                                    address_2: address[:address_2],
                                    address_3: address[:address_3],
                                    city: address[:city],
                                    county: address[:county],
                                    state: address[:state],
                                    location_state_code: address[:location_state_code],
                                    full_text: address[:full_text],
                                    zip: address[:zip],
                                    country_name: address[:country_name]}),
              email: Email.new({kind: email[:kind],
                                address: email[:address]})
            )
            @person.employer_staff_roles << EmployerStaffRole.new(
              person: @person,
              :benefit_sponsor_employer_profile_id => @profile.id,
              is_owner: false,
              aasm_state: 'is_applicant',
              coverage_record: coverage_record
            )
            @person.save!
            user = @person.user
            if user && !user.roles.include?("employer_staff")
              user.roles << "employer_staff"
              user.save!
            end
            Success({:message => 'Successfully added employer staff role'})
          end
        end

        def persist_broker_staff
          terminated_brokers_with_same_profile = @person.broker_agency_staff_roles.detect{|role| role if role.benefit_sponsors_broker_agency_profile_id == @profile.id && role.aasm_state == "broker_agency_terminated"}
          Try do
            if terminated_brokers_with_same_profile.present?
              terminated_brokers_with_same_profile.broker_agency_pending!
              Success({:message => 'Successfully moved staff role from terminated to pending'})
            else
              @person.broker_agency_staff_roles << BrokerAgencyStaffRole.new(
                :benefit_sponsors_broker_agency_profile_id => @profile.id
              )
              @person.save!
              user = @person.user
              if user && !user.roles.include?("broker_agency_staff")
                user.roles << "broker_agency_staff"
                user.save!
              end
              Success({:message => 'Successfully added broker staff role'})
            end
          end
        end

        def persist_general_agency_staff
          terminated_ga_with_same_profile = @person.general_agency_staff_roles.detect{|role| role if role.benefit_sponsors_general_agency_profile_id == @profile.id && role.aasm_state == "general_agency_terminated"}

          Try do
            if terminated_ga_with_same_profile.present?
              terminated_ga_with_same_profile.general_agency_pending!
              Success({:message => 'Successfully moved staff role from terminated to pending'})
            else
              @person.general_agency_staff_roles << GeneralAgencyStaffRole.new(
                benefit_sponsors_general_agency_profile_id: @profile.id,
                npn: @profile.general_agency_primary_staff.npn
              )
              @person.save!
              user = @person.user
              if user && !user.roles.include?("general_agency_staff")
                user.roles << "general_agency_staff"
                user.save!
              end
              Success({:message => 'Successfully added general agency staff role'})
            end
          end
        end

        def is_broker_profile?
          @profile.is_a?(BenefitSponsors::Organizations::BrokerAgencyProfile)
        end

        def is_general_profile?
          @profile.is_a?(BenefitSponsors::Organizations::GeneralAgencyProfile)
        end

        def is_dc_employer_profile?
          @profile.is_a?(BenefitSponsors::Organizations::AcaShopDcEmployerProfile)
        end
      end
    end
  end
end
