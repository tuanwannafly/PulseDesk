class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :account,    null: false, foreign_key: true
      t.references :customer,   null: false, foreign_key: true
      t.references :assigned_to, foreign_key: { to_table: :users }

      t.string :subject, null: false
      t.text   :body
      t.string :status,   null: false, default: 'open'
      t.string :priority, null: false, default: 'normal'

      # AI classification outputs
      t.text   :ai_summary
      t.float  :sentiment_score
      t.string :ai_suggested_priority

      t.datetime :first_response_at
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :tickets, %i[account_id status]
    add_index :tickets, %i[account_id priority]
    add_index :tickets, %i[account_id created_at]
    add_index :tickets, %i[account_id assigned_to_id]
    add_index :tickets, %i[account_id sentiment_score]
  end
end
