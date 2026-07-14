class Tag < ApplicationRecord
  include TenantScoped

  has_many :ticket_tags, dependent: :destroy
  has_many :tickets, through: :ticket_tags

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false, scope: :account_id }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name.to_s.downcase.strip
  end
end
