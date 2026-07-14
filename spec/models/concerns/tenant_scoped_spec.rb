require 'rails_helper'

# This is the single most important spec in the entire codebase.
# It proves that TenantScoped + Current.account prevents data leakage
# between tenants sharing the same database.
RSpec.describe 'Multi-tenant isolation', type: :model do
  let!(:acme)    { FactoryBot.create(:account, company_name: 'Acme',    subdomain: 'acme') }
  let!(:globex)  { FactoryBot.create(:account, company_name: 'Globex',  subdomain: 'globex') }

  describe 'Customer' do
    it 'never returns records from another tenant' do
      Current.account = acme
      acme_customer   = FactoryBot.create(:customer, account: acme)
      _globex_record  = FactoryBot.create(:customer, account: globex)

      Current.account = globex
      expect(Customer.count).to eq(1)
      expect(Customer.first.account_id).to eq(globex.id)

      Current.account = acme
      expect(Customer.count).to eq(1)
      expect(Customer.first.id).to eq(acme_customer.id)
    end

    it 'prevents cross-tenant find_by id' do
      Current.account = acme
      acme_customer   = FactoryBot.create(:customer, account: acme)

      Current.account = globex
      expect(Customer.find_by(id: acme_customer.id)).to be_nil
    end

    it 'returns zero records when no tenant is set' do
      Current.account = nil
      FactoryBot.create(:customer, account: acme)
      FactoryBot.create(:customer, account: globex)

      expect(Customer.count).to eq(0)
    end
  end

  describe 'Ticket' do
    it 'scopes queries automatically' do
      Current.account = acme
      acme_ticket = FactoryBot.create(:ticket, account: acme)

      Current.account = globex
      expect(Ticket.where(id: acme_ticket.id)).to be_empty
    end
  end

  describe '.for_account escape hatch' do
    it 'allows admin/background code to query a specific tenant safely' do
      Current.account = nil
      FactoryBot.create(:ticket, account: acme)
      FactoryBot.create(:ticket, account: globex)

      expect(Ticket.for_account(acme).count).to eq(1)
      expect(Ticket.for_account(globex).count).to eq(1)
    end
  end
end
