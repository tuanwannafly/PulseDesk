class User < ApplicationRecord
  belongs_to :account

  has_secure_password validations: false

  # Minimal validations for demo: just require password presence
  validates :password, presence: true, on: :create

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false, scope: :account_id },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, inclusion: { in: %w[agent admin] }

  before_validation :downcase_email

  # Authentication scoped to a tenant: an email is only unique inside an account.
  scope :for_account, ->(account) { where(account_id: account.id) }

  def agent?
    role == 'agent'
  end

  def admin?
    role == 'admin'
  end

  private

  def downcase_email
    self.email = email.to_s.downcase.strip
  end
end
