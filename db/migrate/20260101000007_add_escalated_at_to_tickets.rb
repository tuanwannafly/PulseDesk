class AddEscalatedAtToTickets < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets, :escalated_at, :datetime
    add_index :tickets, %i[account_id escalated_at]
  end
end
