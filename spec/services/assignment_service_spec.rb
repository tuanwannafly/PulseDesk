require 'rails_helper'

RSpec.describe AssignmentService do
  let(:account)  { FactoryBot.create(:account) }
  let(:agent_a)  { FactoryBot.create(:user, account: account, name: 'Agent A') }
  let(:agent_b)  { FactoryBot.create(:user, account: account, name: 'Agent B') }
  let(:customer) { FactoryBot.create(:customer, account: account) }
  let(:ticket)   { FactoryBot.create(:ticket, account: account, customer: customer) }

  before { Current.account = account }

  it 'assigns the ticket to the first caller' do
    result = described_class.new(ticket, agent_a).call

    expect(result.success?).to be(true)
    expect(ticket.reload.assigned_to_id).to eq(agent_a.id)
  end

  it 'returns failure if a second agent tries to claim an already-assigned ticket' do
    described_class.new(ticket, agent_a).call

    result = described_class.new(ticket.reload, agent_b).call

    expect(result.success?).to be(false)
    expect(result.error).to include('already assigned')
    expect(ticket.reload.assigned_to_id).to eq(agent_a.id)
  end

  it 'is concurrency-safe: only one of two concurrent claims wins', :concurrency do
    # We use a barrier (a Queue) to release two threads at the exact same time.
    # Whichever thread acquires the row-level lock first wins.
    queue   = Queue.new
    results = Queue.new

    threads = [agent_a, agent_b].map do |agent|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          # Make sure each thread uses its own AR connection
          queue.pop
          result = described_class.new(ticket.reload, agent).call
          results << result
        end
      end
    end

    # Release both threads
    2.times { queue << :go }
    threads.each(&:join)

    outcomes = []
    outcomes << results.pop until results.empty?

    winners = outcomes.select(&:success?)
    losers  = outcomes.reject(&:success?)

    expect(winners.size).to eq(1)
    expect(losers.size).to eq(1)
    expect(ticket.reload.assigned_to_id).to eq(winners.first.ticket.assigned_to_id)
  end
end
