class CreateUserChats < ActiveRecord::Migration
  def change
    create_table :user_chats do |t|
      t.integer :m_from
      t.integer :m_to
      t.text :message
      t.timestamps
    end
  end
end
