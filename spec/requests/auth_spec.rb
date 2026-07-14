require 'rails_helper'

RSpec.describe 'Auth', type: :request do
  let!(:account) { FactoryBot.create(:account, company_name: 'Acme', subdomain: 'acme') }
  let!(:user)    { FactoryBot.create(:user, account: account, email: 'a@acme.test', role: 'admin') }

  it 'logs a user in with correct subdomain + email + password' do
    post '/login', params: { subdomain: 'acme', email: 'a@acme.test', password: 'password123' }
    expect(response).to redirect_to(root_path)
  end

  it 'rejects wrong password' do
    post '/login', params: { subdomain: 'acme', email: 'a@acme.test', password: 'WRONG' }
    expect(response.body).to include('Invalid email or password')
  end

  it 'rejects unknown subdomain' do
    post '/login', params: { subdomain: 'nope', email: 'a@acme.test', password: 'password123' }
    expect(response.body).to include('Unknown workspace')
  end

  it 'rejects email belonging to a different tenant' do
    other = FactoryBot.create(:account, subdomain: 'globex')
    _other_user = FactoryBot.create(:user, account: other, email: 'a@globex.test')

    post '/login', params: { subdomain: 'acme', email: 'a@globex.test', password: 'password123' }
    expect(response.body).to include('Invalid email or password')
  end

  it 'logs out' do
    post '/login', params: { subdomain: 'acme', email: 'a@acme.test', password: 'password123' }
    delete '/logout'
    expect(response).to redirect_to(login_path)
  end

  it 'redirects unauthenticated visitors to /login' do
    get '/tickets'
    expect(response).to redirect_to(login_path)
  end
end
