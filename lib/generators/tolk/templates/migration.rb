class CreateTolkTables < ActiveRecord::Migration
  def self.up
    create_table :tolk_locales do |t|
      t.string   :name
      t.datetime :created_at
      t.datetime :updated_at
    end

    #add_index :tolk_locales, :name, :unique => true

    create_table :tolk_phrases do |t|
      t.text     :key
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :tolk_translations do |t|
      t.integer  :phrase_id
      t.integer  :locale_id
      t.integer  :file_path_id
      t.text     :text
      t.text     :previous_text
      t.boolean  :primary_updated, :default => false
      t.datetime :created_at
      t.datetime :updated_at
    end

    #add_index :tolk_translations, [:phrase_id, :locale_id], :unique => true

    create_table "tolk_file_paths", :force => true do |t|
      t.string   "value"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "tolk_translate_results", :force => true do |t|
      t.integer  "locale_id"
      t.integer  "phrase_id"
      t.text     "json"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    # remove_index :tolk_translations, :column => [:phrase_id, :locale_id]
    # remove_index :tolk_locales, :column => :name

    drop_table :tolk_translations
    drop_table :tolk_phrases
    drop_table :tolk_locales
    drop_table :tolk_file_paths
    drop_table :tolk_translate_results
  end
end
