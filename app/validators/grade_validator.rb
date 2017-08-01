class GradeValidator < ActiveModel::Validator
  def validate(record)
    grade_rule = Setting.grade.validate_rule[record.parent.grade.name]

    record.errors.add :base, "二正部门下不能再新建子机构" if grade_rule.empty?
    record.errors.add :grade_id, "#{record.parent.grade.display_name}下只能新建#{CodeTable::DepartmentGrade.where(:name => grade_rule).map(&:display_name).join(',')}部门" unless grade_rule.include?(record.grade.name)
  end
end
