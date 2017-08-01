class AddNoneToDegrees < ActiveRecord::Migration
  def change
    CodeTable::Degree.create(display_name: '无')
  end
end
