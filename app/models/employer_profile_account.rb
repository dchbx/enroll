class EmployerProfileAccount
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_profile

  field :next_premium_due_on, type: Date
  field :next_premium_amount, type: Money
  field :aasm_state, type: String, default: "binder_pending"

  embeds_many :premium_payments
  embeds_many :workflow_state_transitions, as: :transitional

  accepts_nested_attributes_for :premium_payments

  validates_presence_of :next_premium_due_on, :next_premium_amount

  scope :active,      ->{ not_in(aasm_state: %w(canceled terminated)) }


  def last_premium_payment
    return premium_payments.first if premium_payments.size == 1
    premium_payments.order_by(:paid_on.desc).limit(1).first
  end

  def self.find(id)
    org = Organization.where(:"employer_profile.employer_profile_account._id" => id)
    org.first.employer_profile.employer_profile_account
  end

  def latest_workflow_state_transition
    workflow_state_transitions.order_by(:'transition_at'.desc).limit(1).first
  end

  def first_day_of_month?
    TimeKeeper.date_of_record.day == 1
  end

  # TODO: implement this
  def notify_employees
  end

  aasm do
    # Initial open enrollment period closed, first premium payment not received/processed
    state :binder_pending, initial: true
    state :binder_paid, :after_enter => :credit_binder

    state :current                                           # Premium payment received before next invoice is generated
    state :invoiced                                          # Premium payment up-to-date
    state :past_due                                          # Premium payment 1-29 days past due
    state :delinquent,  :after_enter => :notify_employees    # Premium payment 30-60 days past due - send notices to employees
    state :suspended,   :after_enter => :suspend_benefit     # Premium payment 61-90 - transmit terms to carriers with retro date

    state :canceled,    :after_enter => :cancel_benefit      # Coverage never took effect, through either voluntarily withdrawal or binder non-payment
    state :terminated,  :after_enter => :terminate_benefit   # Premium payment > 90 days past due (day 91) or Employer voluntarily terminates

    # Binder payment credit received and allocated to account
    event :allocate_binder_payment, :after => :record_transition do
      transitions from: :binder_pending, to: :binder_paid
    end

    # A new billing period begins the first day of each month
    event :advance_billing_period, :guard => :first_day_of_month?, :after => :record_transition do

      # Commented due initial ER plan year cancellation issues ticket 16300
      # transitions from: :binder_pending, to: :canceled #, :after => :expire_enrollment
      transitions from: :binder_pending, to: :binder_pending
      transitions from: :binder_paid, to: :invoiced, :after => :enroll_employer
      transitions from: :current, to: :invoiced
      transitions from: :invoiced, to: :past_due
      transitions from: :past_due, to: :delinquent
      transitions from: :delinquent, to: :suspended
      transitions from: :suspended, to: :terminated

      # april 10th open enrollment ends => binder pending
      # april 15th binder is due, paid (allocate binder payment happened) => binder paid, not paid => binder pending
      # may 1st plan year start, binder paid => invoiced (due may 31st), binder pending => canceled
      # may 20th paid bill due 31st, invoiced => current
      # june 1st haven't paid bill, invoiced => past_due
    end

    # Premium payment credit received and allocated to account
    event :advance_coverage_period, :after => :record_transition do
      transitions from: [:invoiced, :past_due, :delinquent], to: :current
      transitions from: :suspended, to: :current, :after => :reinstate_employer
    end

    # Premium payment reversed and account debited
    event :reverse_coverage_period, :after => [:record_transition] do

      transitions from: :binder_paid, to: :binder_pending, :guard => :is_before_plan_year_start?, :after => :reverse_binder
      # transitions from: :invoiced, to: :canceled, :guard => :was_last_state?

      # TODO -- add complex state transitions
      # transitions from: [:current, :invoiced], to: :delinquent, :guard => :was_last_state?

      # transitions from: :binder_paid, to: :canceled, :after => :revert_state
      # transitions from: :current, to: :invoiced
      # transitions from: :invoiced, to: :past_due
      # transitions from: :past_due, to: :delinquent

      # transitions from: :delinquent, to: :suspended
      # may 1 invoiced, may 10 paid(1), june 1 invoiced, june 5 paid(2), june 6 nsf(1)

      # binder_paid, wst = [binder_pending, binder_paid]
      # reverse_coverage_period
      # transition happens
      # wst = [binder_pending, binder_paid, binder_pending]
      # revert_state happens

    end
  end

private
  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state,
      event: aasm.current_event,
      transition_at: Time.now.utc
    )
  end

  def revert_state
    self.aasm_state = latest_workflow_state_transition.to_state
  end

  def is_before_plan_year_start?
    employer_profile.published_plan_year.is_before_start?
  end

  def reinstate_employer
    employer_profile.employer_reinstated!
  end

  def credit_binder
    employer_profile.binder_credited!
  end

  def reverse_binder
    employer_profile.binder_reversed!
  end

  def enroll_employer
    employer_profile.enroll_employer!
  end

  def expire_enrollment
    employer_profile.enrollment_expired!
  end

  def cancel_benefit
    employer_profile.benefit_canceled! if employer_profile.may_benefit_canceled?
  end

  def suspend_benefit
    employer_profile.benefit_suspended!
  end

  def terminate_benefit
    employer_profile.benefit_terminated!
  end


end
