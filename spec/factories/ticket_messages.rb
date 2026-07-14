FactoryBot.define do
  factory :ticket_message do
    # Explicitly set account so TenantScoped default_scope doesn't filter it out
    association :account
    association :ticket
    association :customer
    sender_type { 'customer' }
    body { 'A message' }
  end

  factory :agent_message, parent: :ticket_message do
    association :user
    sender_type { 'agent' }
  end
end
