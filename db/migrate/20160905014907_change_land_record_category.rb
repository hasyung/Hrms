class ChangeLandRecordCategory < ActiveRecord::Migration
  def change
  	inner = LandRecord.where("category = 'FOC空勤数据(国内)' or category = 'FOC空勤数据(国外)'")
  	inner.update_all(category: 'FOC空勤数据') unless inner.blank? 
  	outer = LandRecord.where("category = 'FOC飞行员数据(国内)' or category = 'FOC飞行员数据(国外)'")
  	outer.update_all(category: 'FOC飞行数据') unless outer.blank? 
  end
end
