class CreateUploads < ActiveRecord::Migration[7.2]
  def change
    create_table :uploads do |t|
      t.string :name
      t.string :size
      t.boolean :is_public, default: false
      t.string :file_path
      t.references :user, null: false, index: true, foreign_key: true
      t.string :content_type

      t.timestamps
    end
  end
end
