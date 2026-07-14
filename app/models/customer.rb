class Customer < ApplicationRecord
  include TenantScoped

  has_many :tickets, dependent: :destroy

  validates :name,  presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :downcase_email

  def display_name
    "#{name} <#{email}>"
  end

  private

  def downcase_email
    self.email = email.to_s.downcase.strip
  end
end
