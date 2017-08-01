class SetBook::Info < ActiveRecord::Base
  belongs_to :employee

  def generate_change_record(action_type, info_params, department_change = false)
    @employee = self.employee

    if action_type == "create"
      @hash = {
        category:                  "create",
        new_bank_no:               info_params[:bank_no],
        new_salary_category:       info_params[:salary_category],
        new_employee_category:     info_params[:employee_category],
        new_deparment_name:        @employee.department.full_name,
        new_deparment_set_book_no: Department.get_set_book_no(@employee.department),
      }
    else
      @hash = {
        category: "update"
      }

      if self.bank_no != info_params[:bank_no]
        @hash.merge!({
          old_bank_no: self.bank_no,
          new_bank_no: info_params[:bank_no],
        })
      end

      if self.salary_category != info_params[:salary_category]
        @hash.merge!({
          old_salary_category: self.salary_category,
          new_salary_category: info_params[:salary_category],
        })
      end

      if self.employee_category != info_params[:employee_category]
        @hash.merge!({
          old_employee_category: self.employee_category,
          new_employee_category: info_params[:employee_category]
        })
      end

      if department_change
        old_dep = Department.find info_params[:prev_department_id]
        new_dep = Department.find info_params[:department_id]

        @hash.merge!({
          old_deparment_name: old_dep.get_full_name,
          new_deparment_name: new_dep.get_full_name,
          old_deparment_set_book_no: Department.get_set_book_no(old_dep),
          new_deparment_set_book_no: Department.get_set_book_no(new_dep),
        })
      else
        old_dep = @employee.department
        new_dep = old_dep

        @hash.merge!({
          old_deparment_name: old_dep.get_full_name,
          new_deparment_name: new_dep.get_full_name,
          old_deparment_set_book_no: Department.get_set_book_no(old_dep),
          new_deparment_set_book_no: Department.get_set_book_no(new_dep),
        })
      end
    end

    begin
      SetBook::Info.transaction do
        @employee.set_book_change_records.create!(@hash)
        self.update!(info_params) unless department_change
        true
      end
    rescue
      false
    end
  end
end
