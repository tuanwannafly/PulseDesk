class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :tags, dependent: :destroy

  validates :company_name, presence: true
  validates :subdomain, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: { with: /\A[a-z0-9-]+\z/, message: 'only lowercase letters, numbers, hyphens' }

  validates :plan, inclusion: { in: %w[free pro enterprise] }

  before_validation :normalize_subdomain

  def to_param
    subdomain
  end

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip
  end
end
