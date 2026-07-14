require 'rails_helper'

RSpec.describe Account, type: :model do
  it 'is valid with company_name, subdomain, plan' do
    expect(FactoryBot.build(:account)).to be_valid
  end

  it 'requires a subdomain' do
    a = FactoryBot.build(:account, subdomain: nil)
    expect(a).not_to be_valid
  end

  it 'enforces unique subdomain (case-insensitive)' do
    FactoryBot.create(:account, subdomain: 'acme')
    dup = FactoryBot.build(:account, subdomain: 'ACME')
    expect(dup).not_to be_valid
  end

  it 'rejects invalid subdomain characters' do
    a = FactoryBot.build(:account, subdomain: 'Has Spaces!')
    expect(a).not_to be_valid
  end

  it 'rejects unknown plans' do
    a = FactoryBot.build(:account, plan: 'platinum')
    expect(a).not_to be_valid
  end

  it 'downcases subdomain before validation' do
    a = FactoryBot.create(:account, subdomain: '  AcMe  ')
    expect(a.subdomain).to eq('acme')
  end
end
