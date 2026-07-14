require 'rails_helper'

# End-to-end request specs: full ticket lifecycle + cross-tenant safety.
RSpec.describe 'Ticket lifecycle', type: :request do
  let!(:acme)   { FactoryBot.create(:account, company_name: 'Acme',   subdomain: 'acme',   plan: 'pro') }
  let!(:globex) { FactoryBot.create(:account, company_name: 'Globex', subdomain: 'globex', plan: 'pro') }
  let!(:acme_user)    { FactoryBot.create(:user, account: acme,   email: 'admin@acme.test',   role: 'admin') }
  let!(:globex_user)  { FactoryBot.create(:user, account: globex, email: 'admin@globex.test', role: 'admin') }
  let!(:acme_customer)   { FactoryBot.create(:customer, account: acme,   email: 'cust@acme.test') }
  let!(:globex_customer) { FactoryBot.create(:customer, account: globex, email: 'cust@globex.test') }

  def login_as(user)
    post '/login', params: { subdomain: user.account.subdomain, email: user.email, password: 'password123' }
  end

  it 'allows an Acme user to create, view, claim and resolve a ticket' do
    login_as(acme_user)

    # Create
    expect do
      post '/tickets', params: {
        ticket: {
          subject: 'Need help',
          body: 'My dashboard is broken',
          customer_id: acme_customer.id,
          priority: 'normal',
          status: 'open'
        }
      }
    end.to change { Ticket.for_account(acme).count }.by(1)

    ticket = Ticket.for_account(acme).last
    expect(response).to redirect_to(ticket_path(ticket))

    # Stub AI to keep the spec fast / offline
    stub_request(:post, /openrouter\.ai/)
      .to_return(status: 200, body: {
        choices: [{ message: { content: '{"summary":"Broken dashboard","sentiment":-0.3,"priority":"high"}' } }]
      }.to_json)

    # Trigger re-classification (would normally be done via Sidekiq)
    perform_enqueued_jobs do
      TicketClassificationJob.perform_later(ticket.id)
    end

    expect(ticket.reload.ai_summary).to eq('Broken dashboard')
    expect(ticket.ai_suggested_priority).to eq('high')

    # Claim
    post claim_ticket_path(ticket)
    expect(ticket.reload.assigned_to_id).to eq(acme_user.id)

    # Reply
    post ticket_ticket_messages_path(ticket), params: { ticket_message: { body: 'Investigating now.' } }
    Current.account = acme
    expect(ticket.reload.messages.last.body).to eq('Investigating now.')

    # Resolve
    post resolve_ticket_path(ticket)
    expect(ticket.reload.status).to eq('resolved')
  end

  it 'prevents Globex from seeing Acme tickets (cross-tenant safety)' do
    # Create a ticket as Acme
    Current.account = acme
    ticket = FactoryBot.create(:ticket, account: acme, customer: acme_customer)
    Current.account = nil

    # Login as Globex
    login_as(globex_user)

    # Globex's inbox should be empty
    get '/tickets'
    expect(response.body).not_to include(ticket.subject)

    # Direct access should 404
    get "/tickets/#{ticket.id}"
    expect(response).to have_http_status(:not_found)
  end

  it 'prevents Globex from updating Acme customers' do
    Current.account = acme
    customer = acme_customer
    Current.account = nil

    login_as(globex_user)

    patch "/customers/#{customer.id}", params: { customer: { name: 'Hacked' } }
    expect(customer.reload.name).not_to eq('Hacked')
  end
end
