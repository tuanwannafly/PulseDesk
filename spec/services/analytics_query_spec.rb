require 'rails_helper'

RSpec.describe AnalyticsQuery do
  let(:account)  { FactoryBot.create(:account, subdomain: 'analytics-acme') }
  let(:other)    { FactoryBot.create(:account, subdomain: 'analytics-globex') }

  before { Current.account = account }

  describe '#average_response_time_per_agent' do
    it 'returns only tickets within the queried account' do
      agent_a = FactoryBot.create(:user, account: account, name: 'A')
      agent_b = FactoryBot.create(:user, account: other,   name: 'B')
      customer = FactoryBot.create(:customer, account: account)
      other_customer = FactoryBot.create(:customer, account: other)

      ticket_a = FactoryBot.create(:ticket, account: account, customer: customer, assigned_to: agent_a)
      ticket_a.update!(first_response_at: ticket_a.created_at + 2.hours)
      FactoryBot.create(:agent_message, account: account, ticket: ticket_a,
                                        user: agent_a, body: 'Hi!')

      other_ticket = FactoryBot.create(:ticket, account: other, customer: other_customer, assigned_to: agent_b)
      other_ticket.update!(first_response_at: other_ticket.created_at + 10.hours)

      result = described_class.new(account_id: account.id).average_response_time_per_agent

      expect(result.rows.size).to eq(1)
      expect(result.rows.first['agent_name']).to eq('A')
      expect(result.rows.first['avg_response_hours']).to be_within(0.1).of(2.0)
    end
  end

  describe '#top_tags' do
    it 'returns tags by usage count, scoped to account' do
      tag1 = FactoryBot.create(:tag, account: account, name: 'billing')
      tag2 = FactoryBot.create(:tag, account: account, name: 'shipping')
      _other_tag = FactoryBot.create(:tag, account: other, name: 'billing')

      customer = FactoryBot.create(:customer, account: account)
      3.times do
        t = FactoryBot.create(:ticket, account: account, customer: customer)
        FactoryBot.create(:ticket_tag, account: account, ticket: t, tag: tag1)
      end
      t = FactoryBot.create(:ticket, account: account, customer: customer)
      FactoryBot.create(:ticket_tag, account: account, ticket: t, tag: tag2)

      result = described_class.new(account_id: account.id).top_tags
      names  = result.rows.map { |r| r['tag_name'] }

      expect(names).to eq(%w[billing shipping])
      expect(result.rows.first['usage_count']).to eq(3)
    end
  end

  it 'raises if account_id is blank' do
    expect do
      described_class.new(account_id: nil).top_tags
    end.to raise_error(ArgumentError)
  end
end
