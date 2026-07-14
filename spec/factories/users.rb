FactoryBot.define do
  sequence(:email) { |n| "user-#{n}@example.test" }

  factory :user do
    account
    name  { 'Test User' }
    email { generate(:email) }
    role  { 'agent' }
    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
