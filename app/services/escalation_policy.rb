# Pure PORO (no AR callbacks) that encapsulates the business rule:
# "If a ticket has been open for more than X hours without an agent reply,
# upgrade its priority."
#
# Lives outside the model so the rule can be unit-tested in isolation
# and tweaked without changing schema or callbacks.
class EscalationPolicy
  THRESHOLD_HOURS = {
    'urgent' => 1,
    'high' => 4,
    'normal' => 24,
    'low' => 72
  }.freeze

  ESCALATION_ORDER = %w[low normal high urgent].freeze

  def self.apply_to_open_tickets!(account_id: nil)
    scope = Ticket.where(status: %w[open pending])
    scope = scope.where(account_id: account_id) if account_id

    scope.find_each { |t| new(t).apply! }
  end

  def self.reset_for(ticket)
    ticket.update_columns(escalated_at: nil) # skip callbacks / validations
  end

  def initialize(ticket)
    @ticket = ticket
  end

  def apply!
    return if @ticket.resolved?
    return if @ticket.escalated_at.present?

    return unless hours_since_creation > threshold

    new_priority = escalate(@ticket.priority)
    return if new_priority == @ticket.priority

    @ticket.update!(priority: new_priority, escalated_at: Time.current)
  end

  def hours_since_creation
    (Time.current - @ticket.created_at) / 3600.0
  end

  def threshold
    THRESHOLD_HOURS.fetch(@ticket.priority, 24)
  end

  private

  def escalate(current_priority)
    idx = ESCALATION_ORDER.index(current_priority) || 1
    ESCALATION_ORDER[[idx + 1, ESCALATION_ORDER.length - 1].min]
  end
end
