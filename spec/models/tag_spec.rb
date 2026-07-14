require 'rails_helper'

RSpec.describe Tag, type: :model do
  let(:account) { FactoryBot.create(:account) }

  before { Current.account = account }

  it 'is valid with name' do
    expect(FactoryBot.build(:tag, account: account)).to be_valid
  end

  it 'enforces unique name within an account' do
    FactoryBot.create(:tag, account: account, name: 'urgent')
    expect(FactoryBot.build(:tag, account: account, name: 'URGENT')).not_to be_valid
  end

  it 'allows same name across accounts' do
    FactoryBot.create(:tag, account: account, name: 'urgent')
    other = FactoryBot.create(:account, subdomain: 'other')
    Current.account = other
    expect(FactoryBot.build(:tag, account: other, name: 'urgent')).to be_valid
  end
end
