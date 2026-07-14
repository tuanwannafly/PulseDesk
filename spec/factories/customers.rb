FactoryBot.define do
  factory :customer do
    account
    name  { Faker::Name.name }
    email { Faker::Internet.unique.email }
    notes { '' }
  end
end
