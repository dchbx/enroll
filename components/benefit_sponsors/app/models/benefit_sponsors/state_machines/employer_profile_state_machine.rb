module BenefitSponsors
  module StateMachines
    module EmployerProfileStateMachine

      extend ActiveSupport::Concern

      included do
        include AASM

        aasm do
          state :applicant, initial: true
          state :registered                 # Employer has submitted valid application
          state :eligible                   # Employer has completed enrollment and is eligible for coverage
          state :binder_paid, :after_enter => [:notify_binder_paid,:notify_initial_binder_paid]
          state :enrolled                   # Employer has completed eligible enrollment, paid the binder payment and plan year has begun
        # state :lapsed                     # Employer benefit coverage has reached end of term without renewal
          state :suspended                  # Employer's benefit coverage has lapsed due to non-payment
          state :ineligible                 # Employer is unable to obtain coverage on the HBX per regulation or policy

          event :advance_date do
            transitions from: :ineligible, to: :applicant, :guard => :has_ineligible_period_expired?
          end

          event :application_accepted, :after => :record_transition do
            transitions from: [:registered], to: :registered
            transitions from: [:applicant, :ineligible], to: :registered
          end

          event :application_declined, :after => :record_transition do
            transitions from: :applicant, to: :ineligible
            transitions from: :ineligible, to: :ineligible
          end

          event :application_expired, :after => :record_transition do
            transitions from: :registered, to: :applicant
          end

          event :enrollment_ratified, :after => :record_transition do
            transitions from: [:registered, :ineligible], to: :eligible, :after => :initialize_account
          end

          event :enrollment_expired, :after => :record_transition do
            transitions from: :eligible, to: :applicant
          end

          event :binder_credited, :after => :record_transition do
            transitions from: :eligible, to: :binder_paid
          end

          event :binder_reversed, :after => :record_transition do
            transitions from: :binder_paid, to: :eligible
          end

          event :enroll_employer, :after => :record_transition do
            transitions from: :binder_paid, to: :enrolled
          end

          event :enrollment_denied, :after => :record_transition do
            transitions from: [:registered, :enrolled], to: :applicant
          end

          event :benefit_suspended, :after => :record_transition do
            transitions from: :enrolled, to: :suspended, :after => :suspend_benefit
          end

          event :employer_reinstated, :after => :record_transition do
            transitions from: :suspended, to: :enrolled
          end

          event :benefit_terminated, :after => :record_transition do
            transitions from: [:enrolled, :suspended], to: :applicant
          end

          event :benefit_canceled, :after => :record_transition do
            transitions from: :eligible, to: :applicant, :after => :cancel_benefit
          end

          # Admin capability to reset an Employer to applicant state
          event :revert_application, :after => :record_transition do
            transitions from: [:registered, :eligible, :ineligible, :suspended, :binder_paid, :enrolled], to: :applicant
          end

          event :force_enroll, :after => :record_transition do
            transitions from: [:applicant, :eligible, :registered], to: :enrolled
          end
        end
      end

      def record_transition
      end
    end
  end
end
