class CreateTicketMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_messages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ticket,  null: false, foreign_key: true
      t.references :user
      t.references :customer

      t.string  :sender_type, null: false # 'agent' or 'customer'
      t.text    :body,        null: false

      t.timestamps
    end

    add_index :ticket_messages, %i[account_id ticket_id created_at]
  end
end
