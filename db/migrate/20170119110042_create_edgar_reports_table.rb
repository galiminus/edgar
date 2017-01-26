class CreateEdgarReportsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :edgar_reports do |t|
      t.string :name
      t.string :account_name
      t.string :account_id
      t.datetime :date
      t.json :adwords_data_raw
      t.json :youtube_data_raw
      t.json :youtube_earned_data_raw
      t.json :body

      t.timestamps
    end
  end
end
