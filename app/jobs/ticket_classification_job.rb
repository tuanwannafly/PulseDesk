# Mirrors Rails app/jobs convention so ActiveJob finds this class automatically.
require 'faraday'
require 'faraday/retry'
require 'json'

class TicketClassificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(ticket_id)
    # Bypass default_scope to find the ticket (default_scope requires Current.account,
    # but background jobs run outside request context). We restore it immediately below.
    ticket = Ticket.unscoped.find_by(id: ticket_id)
    return unless ticket

    Current.account = ticket.account

    result = TicketClassifierService.new(ticket).call

    ticket.update!(
      ai_summary: result[:summary],
      sentiment_score: result[:sentiment],
      ai_suggested_priority: result[:priority]
    )
  ensure
    Current.account = nil
  end
end
