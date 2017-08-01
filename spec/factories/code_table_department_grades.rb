FactoryGirl.define do
	factory :department_grade, :class => 'CodeTable::DepartmentGrade' do
    name "scal"
    display_name "四川航空"

    factory :branch_grade, :class => 'CodeTable::DepartmentGrade' do
      name "branch_company"
      display_name "分公司"
    end

    factory :positive_grade, :class => 'CodeTable::DepartmentGrade' do
      name "positive"
      display_name "一正级"
    end

    factory :deputy_grade, :class => 'CodeTable::DepartmentGrade' do
      name "deputy"
      display_name "副级"
    end

    factory :secondly_positive_grade, :class => 'CodeTable::DepartmentGrade' do
      name "secondly_positive"
      display_name "二正级"
    end
  end
end
