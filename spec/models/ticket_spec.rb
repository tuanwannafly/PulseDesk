require 'rails_helper'

RSpec.describe Ticket, type: :model do
  let(:account)  { FactoryBot.create(:account) }
  let(:customer) { FactoryBot.create(:customer, account: account) }

  before { Current.account = account }

  it 'is valid with required attributes' do
    expect(FactoryBot.build(:ticket, account: account, customer: customer)).to be_valid
  end

  it 'requires a subject' do
    expect(FactoryBot.build(:ticket, account: account, customer: customer, subject: nil)).not_to be_valid
  end

  it 'rejects unknown statuses' do
    t = FactoryBot.build(:ticket, account: account, customer: customer, status: 'frozen')
    expect(t).not_to be_valid
  end

  it 'rejects unknown priorities' do
    t = FactoryBot.build(:ticket, account: account, customer: customer, priority: 'YESTERDAY')
    expect(t).not_to be_valid
  end

  describe '#sentiment_label' do
    it 'is neutral when score is nil' do
      t = FactoryBot.build(:ticket, account: account, customer: customer)
      expect(t.sentiment_label).to eq('neutral')
    end

    it 'is positive for score > 0.2' do
      t = FactoryBot.build(:ticket, account: account, customer: customer, sentiment_score: 0.5)
      expect(t.sentiment_label).to eq('positive')
    end

    it 'is negative for score < -0.2' do
      t = FactoryBot.build(:ticket, account: account, customer: customer, sentiment_score: -0.7)
      expect(t.sentiment_label).to eq('negative')
    end
  end

  describe '#messages_text' do
    it 'joins message bodies in chronological order' do
      t = FactoryBot.create(:ticket, account: account, customer: customer)
      FactoryBot.create(:ticket_message, account: account, ticket: t, customer: customer,
                                         body: 'first',  created_at: 2.minutes.ago)
      FactoryBot.create(:ticket_message, account: account, ticket: t, customer: customer,
                                         body: 'second', created_at: 1.minute.ago)

      expect(t.messages_text).to eq("first\n\nsecond")
    end
  end

  describe '#mark_first_response!' do
    it 'sets first_response_at only once' do
      t = FactoryBot.create(:ticket, account: account, customer: customer)
      t.mark_first_response!
      first = t.first_response_at
      t.mark_first_response!
      expect(t.reload.first_response_at).to eq(first)
    end
  end
end
