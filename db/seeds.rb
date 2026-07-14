# Seeds three demo tenants (Acme, Globex, Initech) so the tenant-isolation
# story can be demoed live: open two browsers, sign into different tenants,
# verify they cannot see each other's tickets.

puts 'Seeding demo data...'

demo_data = [
  {
    tenant: { company_name: 'Acme Corp', subdomain: 'acme', plan: 'pro' },
    users: [
      { name: 'Alice Admin', email: 'admin@acme.test',  role: 'admin' },
      { name: 'Aiden Agent', email: 'agent@acme.test',  role: 'agent' }
    ],
    tags: %w[billing shipping urgent refund],
    tickets: [
      { subject: 'Cannot login',         body: 'I keep getting "invalid credentials" errors.', priority: 'high',
        status: 'open' },
      { subject: 'Where is my package?', body: 'Order #1234 has been stuck for 5 days.', priority: 'normal',
        status: 'open' },
      { subject: 'Refund question',      body: 'I was charged twice this month, please help!', priority: 'urgent',
        status: 'open' }
    ]
  },
  {
    tenant: { company_name: 'Globex', subdomain: 'globex', plan: 'free' },
    users: [
      { name: 'Greta Globex', email: 'admin@globex.test', role: 'admin' }
    ],
    tags: %w[bug feature-request onboarding],
    tickets: [
      { subject: 'Mobile app crashes', body: 'Crashes when I open settings on Android.', priority: 'high',   status: 'open' },
      { subject: 'Dark mode request',  body: 'Any plans for a dark mode?',               priority: 'low',    status: 'pending' }
    ]
  },
  {
    tenant: { company_name: 'Initech', subdomain: 'initech', plan: 'enterprise' },
    users: [
      { name: 'Ivan Initech', email: 'admin@initech.test', role: 'admin' },
      { name: 'Iris Initech', email: 'iris@initech.test',  role: 'agent' }
    ],
    tags: %w[enterprise sla critical],
    tickets: [
      { subject: 'SLA breach report', body: 'Last month we had 2 SLA breaches.',           priority: 'urgent', status: 'open' },
      { subject: 'Add SSO support',   body: 'We need SAML for our enterprise plan.',       priority: 'normal', status: 'open' }
    ]
  }
]

demo_data.each do |cfg|
  # Create account (unscoped — no TenantScoped yet)
  tenant = Account.find_or_create_by!(subdomain: cfg[:tenant][:subdomain]) do |a|
    a.company_name = cfg[:tenant][:company_name]
    a.plan         = cfg[:tenant][:plan]
  end

  # Set Current.account so default_scope works for child records
  Current.account = tenant

  # Users
  cfg[:users].each do |u|
    user = User.find_or_initialize_by(account_id: tenant.id, email: u[:email])
    user.name     = u[:name]
    user.role     = u[:role]
    user.password = 'password123' if user.new_record?
    user.save!
  end

  # Tags
  cfg[:tags].each do |name|
    Tag.find_or_create_by!(account_id: tenant.id, name: name)
  end

  admin = tenant.users.find_by(role: 'admin')

  # Tickets + messages
  cfg[:tickets].each do |t|
    customer = Customer.find_or_create_by!(account_id: tenant.id,
                                           email: "customer-#{t[:subject].parameterize}@#{tenant.subdomain}.test") do |c|
      c.name = "Customer #{t[:subject][0, 12]}"
    end

    ticket = Ticket.find_or_initialize_by(account_id: tenant.id, subject: t[:subject])
    ticket.customer    = customer
    ticket.assigned_to = admin
    ticket.priority   = t[:priority]
    ticket.status     = t[:status]
    ticket.save!

    ticket.messages.find_or_create_by!(
      body: t[:body], sender_type: 'customer', customer_id: customer.id, account_id: tenant.id
    )
    ticket.messages.find_or_create_by!(
      body: "Hi! We're looking into this for you.",
      sender_type: 'agent', user_id: admin.id, account_id: tenant.id
    )
  end

  Current.account = nil
end

puts 'Done. Demo accounts:'
Account.order(:subdomain).each do |a|
  puts "  - #{a.subdomain.ljust(8)} admin@#{a.subdomain}.test / password123"
end
