namespace :salary do
  desc "import salary person setup setting"
  task import_setup: :environment do
    @base_dir = "#{Rails.root}/public/salary"
    Excel::Salary::KeepSalaryImporter.import("#{@base_dir}/保留明细表.xls")
    Excel::Salary::GroundSubsidyImportor.import("#{@base_dir}/地勤津贴.xls")
    Excel::Salary::MachineSubsidyImportor.import("#{@base_dir}/机务放行补贴.xls")
    Excel::Salary::SecuritySubsidyImportor.import("#{@base_dir}/安检津贴.xls")
    Excel::Salary::FlyerImportor.import("#{@base_dir}/小时费档级.xls")
    Excel::Salary::SubsidyImporter.import("#{@base_dir}/劳务津补贴.xlsx")
    Excel::Salary::OfficialCarSalaryImporter.import("#{@base_dir}/2016年度公务用车费用标准.xls")
    Excel::Salary::HonorSubsidyImporter.import("#{@base_dir}/飞行安全荣誉津贴.xls")
    Excel::Salary::PlacementSubsidyImporter.import("#{@base_dir}/安置补贴.xls")
    Excel::Salary::SalaryPositionBaseImportor.import_flyer_position_base("#{@base_dir}/飞行员基本岗位工资.xls")
    Excel::Salary::PositionSalaryImportor.import("#{@base_dir}/岗工自然晋升总表.xlsx")
    Excel::Salary::CommunicateAllowanceImportor.import("#{@base_dir}/通讯补贴.xlsx")
    Excel::Salary::PerformanceImportor.import("#{@base_dir}/考核性收入.xlsx")
    Excel::Salary::PerformanceSpecialImportor.import("#{@base_dir}/考核性收入_特殊情况.xlsx")
    Excel::Salary::LeaderSalarySetupImporter.import("#{@base_dir}/考核性收入_干部.xls")
    Excel::Salary::TemperatureSubsidyImportor.import("#{@base_dir}/高温津贴.xls")
  end

  desc "import salary person setup hours fee"
  task import_hours_fee: :environment do
    @base_dir = "#{Rails.root}/public/salary"
    Excel::Salary::FlyerImportor.import("#{@base_dir}/小时费档级.xls")
  end

  desc "import salary temperature subsidy setting"
  task import_temperature_subsidy: :environment do
    @base_dir = "#{Rails.root}/public/salary"
    Excel::Salary::TemperatureSubsidyImportor.import("#{@base_dir}/高温津贴.xls")
  end

  desc "import leader salary setup importer"
  task import_leader_salary_setup_importer: :environment do |variable|
    @base_dir = "#{Rails.root}/public/salary"
    Excel::Salary::LeaderSalarySetupImporter.import("#{@base_dir}/考核性收入_干部.xls")
  end
end

namespace :social do
  # 支持重复运行命令
  desc "import social person setup setting"
  task import_setup: :environment do
    @base_dir = "#{Rails.root}/public/social"
    Excel::SocialSetupImportor.import("#{@base_dir}/社保基数个人设置.xls")
  end
end

namespace :employee do
  # 支持重复运行命令
  desc "import employee early retire"
  task early_retire: :environment do
    @base_dir = "#{Rails.root}/public/employee"
    Excel::EarlyRetireEmployeeImportor.import("#{@base_dir}/退养人员花名册.xls")
  end

  desc "import category to employees and set book info"
  task import_category: :environment do
  	@base_dir = "#{Rails.root}/public"
  	Excel::CategoryImporter.import("#{@base_dir}/201606帐套汇总.xlsx")
  end

  desc "import pcategory to employee"
  task import_pcategory: :environment do
    @base_dir = "#{Rails.root}/public"
    Excel::PCategoryImportor.import("#{@base_dir}/考核性收入干部分类.xlsx")
  end
end

namespace :annuity do
  # 支持重复运行命令
  desc 'init employee annuity config'
  task init: :environment do
    @base_dir = "#{Rails.root}/public/annuity"
    Excel::Annuity::AnnuitySetupImportor.import_annuity_account("#{@base_dir}/年金保险公司表.xls")
    Excel::Annuity::AnnuitySetupImportor.import_annuity_info("#{@base_dir}/企业年金缴费明细表.xls")
  end
end

namespace :employee do
  desc "修改人员的入钢时间"
  task change_employee_start_scal_time: :environment do
    employee_id = 32396
    EmployeePosition.unscoped.where(employee_id:employee_id).update_all(start_date:'2014-09-25')
    Employee::WorkExperience.where(employee_id:employee_id).update_all(start_date:'2014-09-25')
  end
end





























