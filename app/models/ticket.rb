class Ticket < ApplicationRecord
  include TenantScoped

  STATUSES   = %w[open pending resolved closed].freeze
  PRIORITIES = %w[low normal high urgent].freeze

  belongs_to :customer
  belongs_to :assigned_to, class_name: 'User', optional: true

  has_many :messages, class_name: 'TicketMessage', dependent: :destroy
  has_many :ticket_tags, dependent: :destroy
  has_many :tags, through: :ticket_tags

  validates :subject,  presence: true
  validates :status,   inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  scope :open,      -> { where(status: 'open') }
  scope :pending,   -> { where(status: 'pending') }
  scope :resolved,  -> { where(status: %w[resolved closed]) }
  scope :by_status,   ->(s) { s.present? ? where(status: s) : all }
  scope :by_priority, ->(p) { p.present? ? where(priority: p) : all }
  scope :recent,    -> { order(created_at: :desc) }

  before_validation :assign_default_account, on: :create

  # Used by the AI classifier service
  def messages_text
    messages.order(:created_at).pluck(:body).join("\n\n")
  end

  def sentiment_label
    return 'neutral' if sentiment_score.nil?

    if sentiment_score >  0.2 then 'positive'
    elsif sentiment_score < -0.2 then 'negative'
    else 'neutral'
    end
  end

  def sentiment_color
    {
      'positive' => 'green',
      'neutral' => 'gray',
      'negative' => 'red'
    }[sentiment_label]
  end

  def mark_first_response!
    return if first_response_at.present?

    update!(first_response_at: Time.current)
  end

  def resolved?
    %w[resolved closed].include?(status)
  end

  private

  def assign_default_account
    self.account_id ||= Current.account_id
  end
end
