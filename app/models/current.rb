class Current < ActiveSupport::CurrentAttributes
  attribute :account, :user, :request_id

  def self.account_id
    account&.id
  end

  def self.tenant_safe?
    account.present?
  end
end
