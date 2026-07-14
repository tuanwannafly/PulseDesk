require 'rails_helper'

RSpec.describe TicketMessage, type: :model do
  let(:account)  { FactoryBot.create(:account) }
  let(:customer) { FactoryBot.create(:customer, account: account) }
  let(:ticket)   { FactoryBot.create(:ticket, account: account, customer: customer) }
  let(:user)     { FactoryBot.create(:user, account: account) }

  before { Current.account = account }

  it 'is valid when linked to a customer' do
    m = FactoryBot.build(:ticket_message, account: account, ticket: ticket, customer: customer)
    expect(m).to be_valid
  end

  it 'is valid when linked to a user (agent)' do
    m = FactoryBot.build(:agent_message, account: account, ticket: ticket, user: user)
    expect(m).to be_valid
  end

  it 'is invalid without sender association' do
    m = FactoryBot.build(:ticket_message, account: account, ticket: ticket,
                                          customer: nil, user: nil)
    expect(m).not_to be_valid
  end

  it 'rejects unknown sender_type' do
    m = FactoryBot.build(:ticket_message, account: account, ticket: ticket,
                                          customer: customer, sender_type: 'bot')
    expect(m).not_to be_valid
  end

  describe 'after agent reply' do
    it 'sets ticket.first_response_at' do
      FactoryBot.create(:agent_message, account: account, ticket: ticket, user: user)
      expect(ticket.reload.first_response_at).to be_present
    end
  end
end
