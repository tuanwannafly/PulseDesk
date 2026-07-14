require 'rails_helper'

RSpec.describe EscalationPolicy do
  let(:account)  { FactoryBot.create(:account) }
  let(:customer) { FactoryBot.create(:customer, account: account) }

  before { Current.account = account }

  it 'upgrades normal → high after 24 hours open' do
    ticket = FactoryBot.create(:ticket, account: account, customer: customer, priority: 'normal')
    ticket.update_columns(created_at: 25.hours.ago)
    described_class.new(ticket).apply!
    expect(ticket.reload.priority).to eq('high')
  end

  it 'does not escalate if within threshold' do
    ticket = FactoryBot.create(:ticket, account: account, customer: customer, priority: 'normal')
    ticket.update_columns(created_at: 1.hour.ago)
    described_class.new(ticket).apply!
    expect(ticket.reload.priority).to eq('normal')
  end

  it 'never escalates beyond urgent' do
    ticket = FactoryBot.create(:ticket, account: account, customer: customer, priority: 'urgent')
    ticket.update_columns(created_at: 100.hours.ago)
    described_class.new(ticket).apply!
    expect(ticket.reload.priority).to eq('urgent')
  end

  it 'does not escalate resolved tickets' do
    ticket = FactoryBot.create(:ticket, account: account, customer: customer,
                                        priority: 'normal', status: 'resolved')
    ticket.update_columns(created_at: 100.hours.ago)
    described_class.new(ticket).apply!
    expect(ticket.reload.priority).to eq('normal')
  end
end
