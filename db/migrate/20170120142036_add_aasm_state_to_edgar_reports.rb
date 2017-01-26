class AddAasmStateToEdgarReports < ActiveRecord::Migration
  def change
    add_column :edgar_reports, :aasm_state, :string
  end
end
