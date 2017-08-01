class Annuity < ActiveRecord::Base
  belongs_to :employee

  class << self
    def check_annuity_status
      Employee.where(annuity_status: true, annuity_cardinality: 0).count > 0 ? true : false
    end

    #年金年度计算
    def cal_year_annuity_cardinality(last_year)
      employee_labor_relation = Employee::LaborRelation.where(display_name: '合同制').first
      Employee.where(labor_relation_id: employee_labor_relation.id).each do |employee|
        cardinality = SocialRecord.cal_year_annuity_cardinality(employee, last_year)
        employee.update(annuity_cardinality: cardinality)
      end
    end

    def cal_annuity(cal_date)
      employee_labor_relation = Employee::LaborRelation.where(display_name: '合同制').first

      employees  = Employee.includes(
        [:contact, :positions => [:department]]
      ).joins(:department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).where(annuity_status: true)

      ActiveRecord::Base.transaction do
        employees.each do |employee|
          annuity_record = employee.annuities.find_or_create_by(cal_date: cal_date)

          personal_proportion = 0.04
          company_proportion  = self.cal_company_proportion(employee)

          note = nil
          if employee.department.name.include?("商旅公司") #商旅公司员工
            note = "代缴"
          elsif employee.department.name.include?("退休人员管理办公室") #退养员工
            note = "退养"
          end

          annuity_record.update!(
            employee_no:            employee.employee_no,
            employee_name:          employee.name,
            employee_identity_name: employee.identity_name,
            department_name:        employee.department.full_name,
            position_name:          employee.master_position.name,
            mobile:                 employee.contact.mobile,
            identity_no:            employee.identity_no,
            annuity_account_no:     employee.annuity_account_no,
            annuity_cardinality:    employee.annuity_cardinality,
            company_payment:        employee.annuity_cardinality * company_proportion,
            personal_payment:       employee.annuity_cardinality * personal_proportion,
            note:                   note
          )
        end
      end

      #添加特殊备注的年金记录
      cal_annuity_with_note(cal_date)
    end

    def cal_annuity_with_note(cal_date)
      date = Date.parse("#{cal_date}-05").to_time
      begin_time = date.beginning_of_month
      end_time   = date.end_of_month

      ActiveRecord::Base.transaction do
        AnnuityNote.where("created_at > ? and created_at < ?", begin_time, end_time).each do |annuity_note|
          employee = Employee.includes([:contact, :positions => [:department]]).find annuity_note.employee_id

          personal_proportion = 0.04
          company_proportion  = self.cal_company_proportion(employee)

          annuity_record = employee.annuities.find_or_create_by(
            cal_date: cal_date
          )

          case annuity_note.category
          when "retirement" #退休
            note = (annuity_record.note.present? && annuity_record.note != "退休" ) ? "#{annuity_record.note},退休" : "退休"
            hash = {
              company_payment: 0,
              personal_payment: 0,
              note: note
            }
          when "fire" #辞退/辞职
            note = (annuity_record.note.present? && annuity_record.note != "离职") ? "#{annuity_record.note},离职" : "离职"
            hash = {
              company_payment: 0,
              personal_payment: 0,
              note: note
            }
          when "join" #新加入
            note = employee.annuity_account_no.present? ? "新起并且已有账户" : "新起"
            note = annuity_record.note.present? ? "#{annuity_record.note},#{note}" : "#{note}"
            hash = {
              note: note
            }
            #给员工添加annuity_account_no
            employee.update(annuity_account_no: "0")
          when "stop" #停缴
            note = (annuity_record.note.present? && annuity_record.note != "停缴") ? "#{annuity_record.note},停缴" : "停缴"
            hash = {
              company_payment: 0,
              personal_payment: 0,
              note: note
            }
          when "mobile" #手机号变更
            note = (annuity_record.note.present? && annuity_record.note != "手机号码变更") ? "#{annuity_record.note},手机号码变更" : "手机号码变更"
            hash = {
              note: note
            }
          when "identity_no" #身份证变更
            note = (annuity_record.note.present? && annuity_record.note != "身份证号码变更") ? "#{annuity_record.note},身份证号码变更" : "身份证号码变更"
            hash = {
              note: note
            }
          end

          annuity_record.update!(
            {
              employee_no:            employee.employee_no,
              employee_name:          employee.name,
              employee_identity_name: employee.identity_name,
              department_name:        employee.department.full_name,
              position_name:          employee.master_position.name,
              mobile:                 employee.contact.mobile,
              identity_no:            employee.identity_no,
              annuity_account_no:     employee.annuity_account_no,
              annuity_cardinality:    employee.annuity_cardinality,
              company_payment:        employee.annuity_cardinality * company_proportion,
              personal_payment:       employee.annuity_cardinality * personal_proportion
            }.merge(hash)
          )
        end
      end
    end

    def cal_company_proportion(employee)
      duty_proportion = 0
      year_proportion = 0
      technical_grade_proportion = 0

      case employee.duty_rank.try(:display_name)
      when '公司正职','公司副职'
        duty_proportion = 0.16
      when '总师/总监', '总助职'
        duty_proportion = 0.14
      when '一正', '一正级', '一副', '一副级', '分公司级'
        duty_proportion = 0.12
      when '二正', '二正级', '二副', '二副级'
        duty_proportion = 0.10
      end

      case employee.salary_person_setup.try(:technical_grade)
      when /^公司级专业技术专家/
        technical_grade_proportion = 0.12
      when /^部门级专业技术专家/
        technical_grade_proportion = 0.12
      when /^部门级专业技术专员/
        technical_grade_proportion = 0.10
      end

      if employee.join_scal_date.present? && employee.join_scal_date <= Date.today.last_year.end_of_year - 20.year
        year_proportion = 0.10
      elsif employee.join_scal_date.present? && employee.join_scal_date > Date.today.last_year.end_of_year - 20.year && employee.join_scal_date <= Date.today.last_year.end_of_year - 10.year
        year_proportion = 0.08
      else
        year_proportion = 0.06
      end
      [duty_proportion, year_proportion, technical_grade_proportion].max
    end
  end
end
