module WorkflowUser
  extend ActiveSupport::Concern

  SPECIAL_FLOW_USER = %w(hr_labor_relation_member party_member hr_leader training_member 
      hr_payment_member flight_member it_director it_chairman)

  module ClassMethods

    def department_hr(department_id)
      department = Department.find_by(id: department_id)
      relations = department ? get_ralation_by_department_hr(department, __method__.to_s) : nil
      get_employee_ids_by_positions(relations.map(&:position_ids).flatten.uniq)
    end

    def file_manager(department_id)
      department = Department.find_by(id: department_id)
      department = department ? get_assign_department(department) : nil
      relations = department ? get_ralation_by_department_hr(department, __method__.to_s) : nil
      get_employee_ids_by_positions(relations.map(&:position_ids).flatten.uniq)
    end

    def file_managers(department_ids)
      department_ids.inject([]) do |dep_ids, department_id|
        file_manager_ids = file_manager(department_id)
        dep_ids << file_manager_ids if file_manager_ids.present?
        dep_ids
      end
    end

    def method_missing(method_name, *args, &block)
      if SPECIAL_FLOW_USER.include?(method_name.to_s)
        relations = FlowRelation.where(role_name: method_name.to_s)
        return get_employee_ids_by_positions(relations.map(&:position_ids).flatten.uniq)
      end

      super
    end

    private
    def get_ralation_by_department_hr(department, role_name)
      relations = FlowRelation.where(department_id: department.id, role_name: role_name)
      if relations.blank? && department.parent.present? && department.parent.serial_number.length >= 6
        relations = get_ralation_by_department_hr(department.parent, role_name)
      end
      relations
    end

    #二级领导serial_number为9位，一级领导serial_number为6位
    def get_assign_department dep
      if dep.serial_number.length == 6
        dep
      elsif dep.serial_number.length > 6
        get_assign_department(dep.parent)
      else
        nil
      end
    end

    def get_employee_ids_by_positions position_ids
      position_ids.inject([]) do |arr, position_id|
        position = Position.find_by(id: position_id)
        arr << position.employees.map(&:id) if position.present? && position.employees.present?
        arr.flatten.uniq
      end
    end
  end
end
