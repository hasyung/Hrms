class AddSalaryConfration < ActiveRecord::Migration
  def change
    if Salary.find_by(category: 'flyer_duty_leader_base', table_type: 'dynamic').blank?
      @record = Salary.find_by(category: 'flyer_leader_base', table_type: 'dynamic')
      @record.update(category: 'flyer_duty_leader_base') if @record

      flyer_leader_base = {
        'flag_list' => ['rate', 'amount', 'X'],
        'flag_names' => {
          'rate' => '系数',
          'amount' => '金额',
          'X' => '默认'
        },
        'flags' => {
          '1' => {
            'rate' => 7.8,
            'amount' => 12920,
            'X' => {
              'grade_list' => [1],
              "edit_mode" => "dialog",
              "format_cell" => "到岗满 %{transfer_years} 年的次月起",
              "transfer_years" => 0.25,
              "expr" => "%{transfer_years} > 0.25"
            }
          }
        }
      }
      Salary.create(category: 'flyer_leader_base', table_type: 'dynamic', form_data: flyer_leader_base)
    end
  end
end
