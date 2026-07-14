class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.references :account, null: false, foreign_key: true
      t.string     :name,    null: false
      t.string     :color,   default: '#6b7280'

      t.timestamps
    end

    add_index :tags, %i[account_id name], unique: true

    create_table :ticket_tags do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ticket,  null: false, foreign_key: true
      t.references :tag,     null: false, foreign_key: true

      t.timestamps
    end

    add_index :ticket_tags, %i[ticket_id tag_id], unique: true
  end
end
