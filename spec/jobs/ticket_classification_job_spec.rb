require 'rails_helper'

RSpec.describe TicketClassificationJob do
  let(:account)  { FactoryBot.create(:account) }
  let(:customer) { FactoryBot.create(:customer, account: account) }
  let(:ticket)   { FactoryBot.create(:ticket, account: account, customer: customer) }

  before do
    # Ensure ticket has a message so the classifier doesn't short-circuit to "AI skipped"
    FactoryBot.create(:ticket_message, account: account, ticket: ticket, customer: customer,
                                       body: 'Need help with billing.')
  end

  before { Current.account = nil }

  it 'is enqueued with default adapter' do
    expect do
      described_class.perform_later(ticket.id)
    end.to have_enqueued_job(described_class).with(ticket.id)
  end

  it 'updates ticket with AI summary on success' do
    stub_request(:post, /openrouter\.ai/)
      .to_return(status: 200, body: {
        choices: [{ message: { content: '{"summary":"OK","sentiment":0.5,"priority":"normal"}' } }]
      }.to_json)

    described_class.new.perform(ticket.id)

    ticket.reload
    expect(ticket.ai_summary).to eq('OK')
    expect(ticket.sentiment_score).to be_within(0.01).of(0.5)
    expect(ticket.ai_suggested_priority).to eq('normal')
  end

  it 'writes fallback values when LLM is down' do
    stub_request(:post, /openrouter\.ai/).to_return(status: 500)

    described_class.new.perform(ticket.id)

    ticket.reload
    expect(ticket.ai_summary).to include('AI unavailable')
    expect(ticket.sentiment_score).to eq(0.0)
  end

  it 'is a no-op if the ticket was deleted' do
    expect do
      described_class.new.perform(99_999)
    end.not_to raise_error
  end
end
