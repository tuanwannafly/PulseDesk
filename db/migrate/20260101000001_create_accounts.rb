class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :company_name, null: false
      t.string :subdomain,    null: false
      t.string :plan,         null: false, default: 'free'

      t.timestamps
    end

    add_index :accounts, :subdomain, unique: true
    add_index :accounts, :plan
  end
end
