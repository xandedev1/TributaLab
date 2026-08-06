class CreateFiscalAuditorUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_auditor_users do |t|
      t.string :username, null: false
      t.string :password_digest, null: false
      t.string :name
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :fiscal_auditor_users, :username, unique: true
  end
end
