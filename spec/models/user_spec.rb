require 'rails_helper'

RSpec.describe User, type: :model do
  let(:account) { FactoryBot.create(:account) }

  before { Current.account = account }

  it 'is valid with valid attributes' do
    expect(FactoryBot.build(:user, account: account)).to be_valid
  end

  it 'requires an email' do
    expect(FactoryBot.build(:user, account: account, email: nil)).not_to be_valid
  end

  it 'enforces unique email inside an account' do
    FactoryBot.create(:user, account: account, email: 'dup@acme.test')
    dup = FactoryBot.build(:user, account: account, email: 'dup@acme.test')
    expect(dup).not_to be_valid
  end

  it 'allows the same email across different accounts' do
    other = FactoryBot.create(:account, subdomain: 'globex')
    FactoryBot.create(:user, account: account, email: 'same@x.test')
    expect(FactoryBot.build(:user, account: other, email: 'same@x.test')).to be_valid
  end

  it 'authenticates with correct password' do
    user = FactoryBot.create(:user, account: account, password: 'secret123')
    expect(user.authenticate('secret123')).to eq(user)
    expect(user.authenticate('WRONG')).to be(false)
  end

  it 'downcases email' do
    u = FactoryBot.create(:user, account: account, email: 'Mixed@Case.Test')
    expect(u.email).to eq('mixed@case.test')
  end

  describe '#admin?' do
    it 'returns true for admin role' do
      u = FactoryBot.build(:user, account: account, role: 'admin')
      expect(u.admin?).to be(true)
      expect(u.agent?).to be(false)
    end
  end
end
