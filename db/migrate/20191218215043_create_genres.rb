class CreateGenres < ActiveRecord::Migration[5.2]
  def change
    create_table :genres do |t|
      t.text :genre
      t.index :genre, unique: true
    end
  end
end
