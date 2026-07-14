class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.references :account, null: false, foreign_key: true
      t.string     :name,    null: false
      t.string     :email,   null: false
      t.string     :password_digest, null: false
      t.string     :role, null: false, default: 'agent'

      t.timestamps
    end

    add_index :users, %i[account_id email], unique: true
    add_index :users, %i[account_id role]
  end
end
