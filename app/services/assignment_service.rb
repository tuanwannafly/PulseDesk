# Concurrency-safe ticket assignment.
#
# Wraps `Ticket.lock.find(id)` in a transaction so that two concurrent
# "Claim" requests cannot both succeed.
#
# Usage:
#   result = AssignmentService.new(ticket, current_user).call
#   result.success? # => true | false
#   result.error    # => "Ticket already assigned to …"
class AssignmentService
  Result = Struct.new(:success?, :error, :ticket, keyword_init: true)

  def initialize(ticket, user)
    @ticket = ticket
    @user   = user
  end

  def call
    Ticket.transaction do
      # PESSIMISTIC LOCK: `SELECT … FOR UPDATE` — second concurrent caller
      # blocks here until the first transaction commits.
      locked = Ticket.lock.find(@ticket.id)

      if locked.assigned_to_id.present? && locked.assigned_to_id != @user.id
        return Result.new(
          success?: false,
          error: "Ticket already assigned to #{locked.assigned_to&.name}",
          ticket: locked
        )
      end

      locked.update!(
        assigned_to_id: @user.id,
        status: locked.status == 'open' ? 'pending' : locked.status
      )

      EscalationPolicy.reset_for(locked)
      Result.new(success?: true, error: nil, ticket: locked)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error: e.message, ticket: @ticket)
  end
end
