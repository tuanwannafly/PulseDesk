class TicketMessage < ApplicationRecord
  include TenantScoped

  SENDER_TYPES = %w[agent customer].freeze

  belongs_to :ticket
  belongs_to :user,     optional: true
  belongs_to :customer, optional: true

  validates :body, presence: true
  validates :sender_type, inclusion: { in: SENDER_TYPES }
  validate  :must_have_sender

  after_create_commit :mark_first_response, if: -> { sender_type == 'agent' }

  private

  def must_have_sender
    return if user_id.present? || customer_id.present?

    errors.add(:base, 'must be associated with a user or a customer')
  end

  def mark_first_response
    ticket.mark_first_response!
  end
end
