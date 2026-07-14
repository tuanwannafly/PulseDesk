require 'rails_helper'

RSpec.describe TicketClassifierService do
  let(:account)  { FactoryBot.create(:account) }
  let(:customer) { FactoryBot.create(:customer, account: account) }
  let(:ticket) do
    t = FactoryBot.create(:ticket, account: account, customer: customer)
    FactoryBot.create(:ticket_message, account: account, ticket: t, customer: customer,
                                       body: 'My package never arrived and I want a refund!')
    t
  end

  before { Current.account = account }

  describe '#call with OpenRouter' do
    it 'parses a valid LLM JSON response and returns expected keys' do
      stub_request(:post, /openrouter\.ai/)
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            choices: [
              { message: { content: '{"summary":"Refund request","sentiment":-0.8,"priority":"high"}' } }
            ]
          }.to_json
        )

      result = described_class.new(ticket).call

      expect(result[:summary]).to eq('Refund request')
      expect(result[:sentiment]).to be_within(0.01).of(-0.8)
      expect(result[:priority]).to eq('high')
    end

    it 'falls back gracefully when the API times out' do
      stub_request(:post, /openrouter\.ai/).to_timeout

      result = described_class.new(ticket).call

      expect(result[:summary]).to include('AI unavailable')
      expect(result[:sentiment]).to eq(0.0)
    end

    it 'falls back gracefully on a 5xx response' do
      stub_request(:post, /openrouter\.ai/).to_return(status: 503, body: '')

      result = described_class.new(ticket).call

      expect(result[:summary]).to include('AI unavailable')
    end

    it 'falls back gracefully when the response is not valid JSON' do
      stub_request(:post, /openrouter\.ai/)
        .to_return(status: 200, body: { choices: [{ message: { content: 'not json' } }] }.to_json)

      result = described_class.new(ticket).call

      expect(result[:summary]).to include('AI unavailable')
    end

    it 'returns AI skipped for empty conversations' do
      empty_ticket = FactoryBot.create(:ticket, account: account, customer: customer)
      result = described_class.new(empty_ticket).call
      expect(result[:summary]).to include('AI skipped')
    end
  end
end
