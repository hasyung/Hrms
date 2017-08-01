module Admin::PermissionsHelper
  def judge_offset(department)
    case department.depth
    when 1
      "margin-left: 0px"
    when 2
      "margin-left: 6px"
    when 3
      "margin-left: 60px"
    when 4
      "margin-left: 120px"
    end
  end

  def judge_icon(department_hr, department)
    department_hr.each do |item|
      if item.position_ids.present? && item.department_id == department.id
        return true
      end
    end
    false
  end

  def get_position_ids(department_hr, department)
    department_hr.each do |item|
      if item.position_ids.present? && item.department_id == department.id
        return item.position_ids
      end
    end
    []
  end

  def flow_relation_name(name)
    FlowRelation.role_names.select{|f| f[1] == name}.first.try(:first)
  end

end
