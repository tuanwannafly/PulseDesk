FactoryBot.define do
  sequence(:subdomain)     { |n| "tenant-#{n}" }
  sequence(:company_name)  { |n| "Company #{n}" }

  factory :account do
    company_name { generate(:company_name) }
    subdomain    { generate(:subdomain) }
    plan         { 'free' }
  end
end
