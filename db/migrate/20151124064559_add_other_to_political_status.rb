class AddOtherToPoliticalStatus < ActiveRecord::Migration
  def change
    CodeTable::PoliticalStatus.create(display_name: '其他')
  end
end
