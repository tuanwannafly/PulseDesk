class TicketTag < ApplicationRecord
  include TenantScoped

  belongs_to :ticket
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: %i[ticket_id account_id] }
end
