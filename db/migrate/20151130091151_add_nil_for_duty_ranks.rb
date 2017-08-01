class AddNilForDutyRanks < ActiveRecord::Migration
  def change
    Employee::DutyRank.find_or_create_by(display_name: '无')
  end
end
