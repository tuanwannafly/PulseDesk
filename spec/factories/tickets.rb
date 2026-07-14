FactoryBot.define do
  factory :ticket do
    account
    customer
    subject  { 'Sample ticket subject' }
    body     { 'This is the initial message of the ticket.' }
    status   { 'open' }
    priority { 'normal' }
  end
end
