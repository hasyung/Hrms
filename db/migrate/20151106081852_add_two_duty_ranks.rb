class AddTwoDutyRanks < ActiveRecord::Migration
  def change
    Employee::DutyRank.find_or_create_by(display_name: '一正级')
    Employee::DutyRank.find_or_create_by(display_name: '二正级')
  end
end
