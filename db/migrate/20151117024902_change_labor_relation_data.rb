class ChangeLaborRelationData < ActiveRecord::Migration
  def change
    xieyi = Employee::LaborRelation.find_by(display_name: '蓝天劳务(协议)')
    xieyi.update(display_name: '蓝天劳务（协议）') if xieyi
    shixi = Employee::LaborRelation.find_by(display_name: '蓝天劳务(实习)')
    shixi.update(display_name: '蓝天劳务（实习）') if shixi
  end
end
