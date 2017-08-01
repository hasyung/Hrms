FactoryGirl.define do
  factory :leave_employee do
    name '严丽珠'
    department "后勤保障部"
    employee_no "007247"
    labor_relation "合同制"
    file_no "06年以前退休无记录"
    change_date "2005-02-17"
    position " "
    employment_status "退休"
    channel "管理"
    gender "女"
    birthday "1950-01-17"
    identity_no "510122195001175926"
    join_scal_date "1988-12-01"
    remark " "

    factory :zhang, :class => 'LeaveEmployee' do
      name "张新华"
      department "工会办公室-退休人员管理办公室"
      employee_no "007239"
      labor_relation "合同制"
      file_no "06年以前退休无记录"
      change_date "2002-08-01"
      position " "
      employment_status "退休"
      channel "管理"
      gender "男"
      birthday "1941-02-02"
      identity_no "51010319410202623X"
      join_scal_date "1987-10-01"
      remark " "
    end
  end

end
