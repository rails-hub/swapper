class CreateUserImages < ActiveRecord::Migration
  def change
    create_table :user_images do |t|
      t.string :avatar_file_name
      t.string :avatar_content_type
      t.integer :avatar_file_size
      t.string :avatar_fingerprint
      t.integer :user_id
      t.timestamps
    end
  end
end
