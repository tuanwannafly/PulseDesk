module TenantScoped
  extend ActiveSupport::Concern

  included do
    # Optional so seed / factory can create records without Current.account set.
    # The validates block below enforces account_id presence instead.
    belongs_to :account, optional: true

    # CRITICAL: This default_scope makes every query tenant-scoped by construction.
    # When Current.account is nil (e.g. background jobs without tenant),
    # we return an empty relation (where(account_id: nil)) instead of all rows.
    default_scope { where(account_id: Current.account_id) }

    # Defense in depth: in case someone calls .unscoped in an unsafe context.
    scope :for_account, ->(account) { unscoped.where(account_id: account.id) }

    # Ensure every persisted record has an account.
    validates :account_id, presence: true, on: %i[create update]

    # Populate account_id from Current.account before validation.
    # Alias so models that call `before_validation :assign_default_account` still work.
    before_validation :assign_default_account

    # Define the actual method here (inside included block so it's an instance method).
    define_method(:assign_default_account) do
      self.account_id ||= Current.account_id
    end
  end
end
