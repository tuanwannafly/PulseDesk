class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.references :account, null: false, foreign_key: true
      t.string     :name,  null: false
      t.string     :email, null: false
      t.text       :notes

      t.timestamps
    end

    add_index :customers, %i[account_id email]
  end
end
