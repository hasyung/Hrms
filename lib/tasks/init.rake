namespace :init do
  desc "import employee last tranfer date"
  task import_tranfer_info: :environment do
    #Logger
    log_path = Rails.root + 'log/tranfer_date_info.log'
    File.delete(log_path) if File.exist?(log_path)
    logger  = Logger.new(log_path)

    book = Spreadsheet.open "#{Rails.root}/public/upgrade_position_grade.xls"
    sheet = book.worksheet 0

    sheet.each_with_index 1 do |row, index|
      employee = Employee.where(employee_no: row[0], name: row[1]).first
      if employee.blank?
        logger.info("#{index} -- #{row[0]} -- #{row[1]} couldn't find") and next
      end
      employee.upgrade_grade_infos.create(
        last_up_date: "#{row[2].to_i}/#{row[3].to_i}/1"
      ).save
    end
  end

  desc "import employee email"
  task import_employee_email: :environment do
    Excel::EmployeeEmailImportor.import("员工邮箱.xlsx")
  end

  desc "import employee familymember"
  task import_familymember: :environment do
    hash = Excel::FamilyMemberImportor.import("亲友.xls")
    puts hash[:path]
  end

  desc "init department set_book_no"
  task init_dep_set_book_no: :environment do
    book = Spreadsheet.open "#{Rails.root}/public/set_book_no.xls"
    sheet = book.worksheet 0
    @errors = []

    sheet.each_with_index do |row, index|
      dep = Department.where(name: row[0])
      if dep.count == 1
        dep.first.update(set_book_no: row[1])
      else
        @errors << "#{index+1}行，存在两个重名部门,或不存在"
      end
    end

    Department.where(name: "运行控制中心", depth: '2').first.update(set_book_no: "021")
    Department.where(name: "综合管理部", depth: '3').first.update(set_book_no: "02301")

    if @errors.size > 0
      puts @errors.join("\r\n").red
    end
  end


  desc "import flyer info"
  task import_flyer_info: :environment do
    #Logger
    log_path = Rails.root + 'log/flyer_info.log'
    File.delete(log_path) if File.exist?(log_path)
    logger  = Logger.new(log_path)

    book = Spreadsheet.open "#{Rails.root}/public/flyer/飞行员信息.xls"
    sheet = book.worksheet 0

    sheet.each_with_index 1 do |row, index|
      employee = Employee.where(employee_no: row[0], name: row[1]).first
      logger.info("#{index} -- #{row[0]} -- #{row[1]} couldn't find") and next if employee.blank?
      employee.build_flyer_info(
        total_fly_time: row[2],
        copilot_date: row[3],
        teacher_A_date: row[4],
        teacher_B_date: row[5],
        teacher_B_date: row[6],
      ).save
    end
  end

  desc "import flyer science subsidy"
  task flyer_science_subsidy: :environment do
    flyer_science_subsidy = {
      "inspect_delegate" => 18000,   # 局方检查代表
      "teacher" => 17000,             # 教员
      "duty_leader" => 15000,        # 责任机长
      "leader" => 8000,              # 机长
      "copilot_special" => 4500,     # 副驾驶特别档
      "copilot_1" => 4500,           # 副驾驶 1
      "copilot_2" => 4500,           # 副驾驶 2
      "copilot_3" => 4500,           # 副驾驶 3
      "copilot_4" => 3000,           # 副驾驶 4
      "copilot_5" => 3000,           # 副驾驶 5
      "copilot_6" => 3000,           # 副驾驶 6
    }

    Salary.create(category: 'flyer_science_subsidy', table_type: 'static', form_data: flyer_science_subsidy)
  end

  desc "init salary_leader"
  task salary_leader: :environment do
    service_leader_perf = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "薪酬等级"
      },
      "flags" => {
        "16" => {
          "rate" => 8.7,
          "amount" => 12180,
          "X" => {
            "format_cell" => "D4",
            "expr" => ""
          }
        },
        "17" => {
          "rate" => 9.3,
          "amount" => 13020,
          "X" => {
            "format_cell" => "D3",
            "expr" => ""
          }
        },
        "18" => {
          "rate" => 10,
          "amount" => 14000,
          "X" => {
            "format_cell" => "D2",
            "expr" => ""
          }
        },
        "19" => {
          "rate" => 10.6,
          "amount" => 14840,
          "X" => {
            "format_cell" => "D1",
            "expr" => ""
          }
        },
        "20" => {
          "rate" => 11.9,
          "amount" => 16660,
          "X" => {
            "format_cell" => "C5",
            "expr" => ""
          }
        },
        "21" => {
          "rate" => 13.2,
          "amount" => 18480,
          "X" => {
            "format_cell" => "C4",
            "expr" => ""
          }
        },
        "22" => {
          "rate" => 14.4,
          "amount" => 20160,
          "X" => {
            "format_cell" => "C3",
            "expr" => ""
          }
        },
        "23" => {
          "rate" => 15.9,
          "amount" => 22260,
          "X" => {
            "format_cell" => "C2",
            "expr" => ""
          }
        },
        "24" => {
          "rate" => 16.5,
          "amount" => 23100,
          "X" => {
            "format_cell" => "C1",
            "expr" => ""
          }
        },
        "25" => {
          "rate" => 17,
          "amount" => 23800,
          "X" => {
            "format_cell" => "B2",
            "expr" => ""
          }
        },
        "26" => {
          "rate" => 18,
          "amount" => 25200,
          "X" => {
            "format_cell" => "B1",
            "expr" => ""
          }
        },
        "27" => {
          "rate" => 19,
          "amount" => 26600,
          "X" => {
            "format_cell" => "A1",
            "expr" => ""
          }
        },
      }
    }

    Salary.create(category: 'service_leader_perf', table_type: 'dynamic', form_data: service_leader_perf)

    information_leader_perf = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "薪酬等级"
      },
      "flags" => {
        "16" => {
          "rate" => 7.4,
          "amount" => 10360,
          "X" => {
            "format_cell" => "D4",
            "expr" => ""
          }
        },
        "17" => {
          "rate" => 8,
          "amount" => 11200,
          "X" => {
            "format_cell" => "D3",
            "expr" => ""
          }
        },
        "18" => {
          "rate" => 8.5,
          "amount" => 11900,
          "X" => {
            "format_cell" => "D2",
            "expr" => ""
          }
        },
        "19" => {
          "rate" => 9.3,
          "amount" => 13020,
          "X" => {
            "format_cell" => "D1",
            "expr" => ""
          }
        },
        "20" => {
          "rate" => 10.7,
          "amount" => 14980,
          "X" => {
            "format_cell" => "C5",
            "expr" => ""
          }
        },
        "21" => {
          "rate" => 11.8,
          "amount" => 16520,
          "X" => {
            "format_cell" => "C4",
            "expr" => ""
          }
        },
        "22" => {
          "rate" => 12.8,
          "amount" => 17920,
          "X" => {
            "format_cell" => "C3",
            "expr" => ""
          }
        },
        "23" => {
          "rate" => 14.1,
          "amount" => 19740,
          "X" => {
            "format_cell" => "C2",
            "expr" => ""
          }
        },
        "24" => {
          "rate" => 15.5,
          "amount" => 21700,
          "X" => {
            "format_cell" => "C1",
            "expr" => ""
          }
        },
        "25" => {
          "rate" => 17,
          "amount" => 23800,
          "X" => {
            "format_cell" => "B2",
            "expr" => ""
          }
        },
        "26" => {
          "rate" => 18,
          "amount" => 25200,
          "X" => {
            "format_cell" => "B1",
            "expr" => ""
          }
        },
        "27" => {
          "rate" => 19,
          "amount" => 26600,
          "X" => {
            "format_cell" => "A1",
            "expr" => ""
          }
        },
      }
    }

    Salary.create(category: 'information_leader_perf', table_type: 'dynamic', form_data: information_leader_perf)

    material_leader_perf = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "薪酬等级"
      },
      "flags" => {
        "16" => {
          "rate" => 7.4,
          "amount" => 10360,
          "X" => {
            "format_cell" => "D4",
            "expr" => ""
          }
        },
        "17" => {
          "rate" => 8,
          "amount" => 11200,
          "X" => {
            "format_cell" => "D3",
            "expr" => ""
          }
        },
        "18" => {
          "rate" => 8.5,
          "amount" => 11900,
          "X" => {
            "format_cell" => "D2",
            "expr" => ""
          }
        },
        "19" => {
          "rate" => 9.3,
          "amount" => 13020,
          "X" => {
            "format_cell" => "D1",
            "expr" => ""
          }
        },
        "20" => {
          "rate" => 10.7,
          "amount" => 14980,
          "X" => {
            "format_cell" => "C5",
            "expr" => ""
          }
        },
        "21" => {
          "rate" => 11.8,
          "amount" => 16520,
          "X" => {
            "format_cell" => "C4",
            "expr" => ""
          }
        },
        "22" => {
          "rate" => 12.8,
          "amount" => 17920,
          "X" => {
            "format_cell" => "C3",
            "expr" => ""
          }
        },
        "23" => {
          "rate" => 14.1,
          "amount" => 19740,
          "X" => {
            "format_cell" => "C2",
            "expr" => ""
          }
        },
        "24" => {
          "rate" => 15.5,
          "amount" => 21700,
          "X" => {
            "format_cell" => "C1",
            "expr" => ""
          }
        },
        "25" => {
          "rate" => 17,
          "amount" => 23800,
          "X" => {
            "format_cell" => "B2",
            "expr" => ""
          }
        },
        "26" => {
          "rate" => 18,
          "amount" => 25200,
          "X" => {
            "format_cell" => "B1",
            "expr" => ""
          }
        },
        "27" => {
          "rate" => 19,
          "amount" => 26600,
          "X" => {
            "format_cell" => "A1",
            "expr" => ""
          }
        },
      }
    }

    Salary.create(category: 'material_leader_perf', table_type: 'dynamic', form_data: material_leader_perf)

    market_leader_perf = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "薪酬等级"
      },
      "flags" => {
        "16" => {
          "rate" => 7,
          "amount" => 9800,
          "X" => {
            "format_cell" => "D4",
            "expr" => ""
          }
        },
        "17" => {
          "rate" => 7.5,
          "amount" => 10500,
          "X" => {
            "format_cell" => "D3",
            "expr" => ""
          }
        },
        "18" => {
          "rate" => 8,
          "amount" => 11200,
          "X" => {
            "format_cell" => "D2",
            "expr" => ""
          }
        },
        "19" => {
          "rate" => 8.7,
          "amount" => 12180,
          "X" => {
            "format_cell" => "D1",
            "expr" => ""
          }
        },
        "20" => {
          "rate" => 10,
          "amount" => 14000,
          "X" => {
            "format_cell" => "C5",
            "expr" => ""
          }
        },
        "21" => {
          "rate" => 11.2,
          "amount" => 15680,
          "X" => {
            "format_cell" => "C4",
            "expr" => ""
          }
        },
        "22" => {
          "rate" => 12.2,
          "amount" => 17080,
          "X" => {
            "format_cell" => "C3",
            "expr" => ""
          }
        },
        "23" => {
          "rate" => 13.5,
          "amount" => 18900,
          "X" => {
            "format_cell" => "C2",
            "expr" => ""
          }
        },
        "24" => {
          "rate" => 15,
          "amount" => 21000,
          "X" => {
            "format_cell" => "C1",
            "expr" => ""
          }
        },
        "25" => {
          "rate" => 17,
          "amount" => 23800,
          "X" => {
            "format_cell" => "B2",
            "expr" => ""
          }
        },
        "26" => {
          "rate" => 18,
          "amount" => 25200,
          "X" => {
            "format_cell" => "B1",
            "expr" => ""
          }
        },
        "27" => {
          "rate" => 19,
          "amount" => 26600,
          "X" => {
            "format_cell" => "A1",
            "expr" => ""
          }
        },
      }
    }

    Salary.create(category: 'market_leader_perf', table_type: 'dynamic', form_data: market_leader_perf)
  end

  desc "init fly time money"
  task salary_other: :environment do
    count = Salary.count

    fly_attendant_hour = {
      'purser_A' => 145,
      'purser_B' => 135,
      'purser_C' => 125,
      'purser_D' => 110,
      'purser_E' => 90,
      'first_class_A' => 75,
      'first_class_B' => 70,
      'attendant_A' => 65,
      'attendant_B' => 58,
      'attendant_C' => 52,
      'trainee_A' => 30,
      'trainee_B' => 20
    }
    Salary.create(category: 'fly_attendant_hour', table_type: 'static', form_data: fly_attendant_hour)

    unfly_allowance_hour = {
      "teacher"  => {
        'rate'   => 13.5,
        'amount' => 14850
      },
      'leader'   => {
        'rate'   => 11.2,
        'amount' => 12320
      },
      'copilot'  => {
        'rate'   => 0,
        'amount' => 2000
      },
      'student'  => {
        'rate'   => 0,
        'amount' => 1000
      }
    }
    Salary.create(category: 'unfly_allowance_hour', table_type: 'static', form_data: unfly_allowance_hour)

    format_service_b_normal_cleaner_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2250,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 2450,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 2600,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_normal_cleaner_base', table_type: 'dynamic', form_data: format_service_b_normal_cleaner_base)

    format_service_b_parking_cleaner_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2400,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 2600,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 2750,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_parking_cleaner_base', table_type: 'dynamic', form_data: format_service_b_parking_cleaner_base)

    format_service_b_hotel_service_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2450,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 2650,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 2800,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_hotel_service_base', table_type: 'dynamic', form_data: format_service_b_hotel_service_base)

    format_service_b_green_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2450,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 2650,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 2800,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_green_base', table_type: 'dynamic', form_data: format_service_b_green_base)

    format_service_b_front_desk_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2650,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 2850,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3000,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_front_desk_base', table_type: 'dynamic', form_data: format_service_b_front_desk_base)

    format_service_b_security_guard_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2750,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 2950,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3100,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_security_guard_base', table_type: 'dynamic', form_data: format_service_b_security_guard_base)

    format_service_b_input_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2800,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3050,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3250,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_input_base', table_type: 'dynamic', form_data: format_service_b_input_base)

    format_service_b_guard_leader1_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2950,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3150,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3300,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_guard_leader1_base', table_type: 'dynamic', form_data: format_service_b_guard_leader1_base)

    format_service_b_device_keeper_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2850,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3150,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3400,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_device_keeper_base', table_type: 'dynamic', form_data: format_service_b_device_keeper_base)

    format_service_b_unloading_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2950,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3200,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3400,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_unloading_base', table_type: 'dynamic', form_data: format_service_b_unloading_base)

    format_service_b_making_water_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 2950,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3150,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3300,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_making_water_base', table_type: 'dynamic', form_data: format_service_b_making_water_base)

    format_service_b_add_water_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 3000,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3300,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3450,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_add_water_base', table_type: 'dynamic', form_data: format_service_b_add_water_base)

    format_service_b_guard_leader2_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 3100,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3300,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3450,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_guard_leader2_base', table_type: 'dynamic', form_data: format_service_b_guard_leader2_base)

    format_service_b_water_light_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 3150,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3350,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3500,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_water_light_base', table_type: 'dynamic', form_data: format_service_b_water_light_base)

    format_service_b_car_repair_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 3300,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3500,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3650,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_car_repair_base', table_type: 'dynamic', form_data: format_service_b_car_repair_base)

    format_service_b_airline_keeper_base = {
      'flag_list'  => [ 'amount', 'A' ],
      'flag_names' => [
        'amount' => '金额',
        'A' => 'A',
      ],
      'flags' => {
        '1' => {
          'amount' => 3300,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 0,
            'format_cell' => '新进',
          }
        },
        '2' => {
          'amount' => 3600,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 5,
            'format_cell' => '本企业经历不少于 5 年',
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '3' => {
          'amount' => 3950,
          'A' => {
            'grade_list' => [1, 2, 3],
            'edit_mode' => 'text',
            'transfer_years' => 10,
            'format_cell' => '本企业经历不少于 10 年',
            "expr" => "%{transfer_years} >= 10"
          }
        }
      }
    }
    Salary.create(category: 'service_b_airline_keeper_base', table_type: 'dynamic', form_data: format_service_b_airline_keeper_base)

    flyer_legend_base = {
      'flag_list' => ['rate', 'amount', 'X'],
      'flag_names' => {
        'rate' => '系数',
        'amount' => '金额',
        'X' => '默认'
      },
      'flags' => {
        '1' => {
          'rate' => 17.8,
          'amount' => 24920,
          'X' => {
            'grade_list' => [1],
            'edit_mode' => 'text',
            'format_cell' => '荣誉等级入岗条件一: 1、曾担任过副总师、总助(含)以上领导职务; 2、现任飞行教员; 3、在公司所飞三种机型上担任过教员; 4、在 1990 年(含)前取得公司机型教员资格;; 5、没有人为原因的严重飞行事故征候以上不良安全记录。 荣誉等级入岗条件二: 1、现任 C 类飞行教员,现有机型教员经历时间 12 年以上; 2、在本公司飞行时间 20000 小时以上; 3、晋升前连续 10 年无人为原因飞行事故征候及以上不良 安全记录; 4、晋升前 8 年无航空安全严重差错; 5、具备高原、特殊机场飞行运行资格; 6、具备独立执行(无专职通信员)国际和地区航线任务的 外语能力。',
          }
        }
      }
    }
    Salary.create(category: 'flyer_legend_base', table_type: 'dynamic', form_data: flyer_legend_base)

    flyer_copilot_base = {
      'flag_list' => ['rate', 'amount', 'X'],
      'flag_names' => {
        'rate' => '系数',
        'amount' => '金额',
        "X" => "默认",
      },
      'flags' => {
        '1'  => {
          'rate'        => 7.4,
          'amount'     => 10360,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间13年以上; 2、在本公司飞行时间10000小时以上;",
            "expr" => "%{drive_work_value} >= 13 and %{fly_time_value} >= 10000"
          }
        },
        '2'  => {
          'rate'         => 6.8,
          'amount'      => 9520,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间11年以上; 2、在本公司飞行时间8000小时以上;",
            "expr" => "%{drive_work_value} >= 11 and %{fly_time_value} >= 8000"
          }
        },
        '3'  => {
          'rate'         => 6.2,
          'amount'      => 8680,
          'X' => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"   => "white",
            "edit_mode"  => "dialog",
            'format_cell'  => "1、副驾驶经历时间9年以上; 2、在本公司飞行时间6000小时以上;",
            "expr" => "%{drive_work_value} >= 9 and %{fly_time_value} >= 6000"
          }
        },
        '4'  => {
          'rate'        => 5.6,
          'amount'     => 7840,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间7年以上; 2、在本公司飞行时间4000小时以上;",
            "expr" => "%{drive_work_value} >= 7 and %{fly_time_value} >= 4000"
          }
        },
        '5'  => {
          'rate'         => 5,
          'amount'      => 7000,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间5年以上; 2、在本公司飞行时间2700小时以上;",
            "expr" => "%{drive_work_value} >= 5 and %{fly_time_value} >= 2700"
          }
        },
        '6'  => {
          'rate'        => 4.5,
          'amount'     => 6300,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间4年以上; 2、在本公司飞行时间2000小时以上;",
            "expr" => "%{drive_work_value} >= 4 and %{fly_time_value} >= 2000"
          }
        },
        '7'  => {
          'rate'        => 4,
          'amount'     => 5600,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间3年以上; 2、在本公司飞行时间1500小时以上;",
            "expr" => "%{drive_work_value} >= 3 and %{fly_time_value} >= 1500"
          }
        },
        '8'  => {
          'rate'         => 3.5,
          'amount'      => 4900,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间2年以上; 2、在本公司飞行时间800小时以上;",
            "expr" => "%{drive_work_value} >= 2 and %{fly_time_value} >= 800"
          }
        },
        '9'  => {
          'rate'        => 3,
          'amount'     => 4200,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "1、副驾驶经历时间1年以上; 2、在本公司飞行时间400小时以上;",
            "expr" => "%{drive_work_value} >= 1 and %{fly_time_value} >= 400"
          }
        },
        '10' => {
          'rate'        => 2.5,
          'amount'     => 3500,
          'X' => {
            "grade_list"  => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color"    => "white",
            "edit_mode"   => "dialog",
            'format_cell' => "入队,成为副驾驶",
            'drive_work_value'  => 0,
            'fly_time_value'  => 0,
          }
        },
      }
    }
    Salary.create(category: 'flyer_copilot_base', table_type: 'dynamic', form_data: flyer_copilot_base)

    manager12_base = {
      'flag_list'  => ['rate','amount', 'G', 'F', 'E', 'B', 'A'],
      'flag_names' => {
        'rate'   => '系数',
        'amount' => '金额',
        'G'      => 'G',
        'F'      => 'F',
        'E'      => 'E',
        'B'      => 'B',
        'A'      => 'A',
      },
      'flags' => {
        '18' => {
          'rate'   => 7.2,
          'amount' => 10080,
          'A' => {
            'grade_list'   => [18, 17, 16, 15],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{job_title_degree} >= '高级'"
          }
        },
        '17' => {
          'rate'   => 6.6,
          'amount' => 9240,
          'A' => {
            'grade_list'   => [18, 17, 16, 15],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 5"
          }
        },
        '16' => {
          'rate'   => 6.1,
          'amount' => 8540,
          'A' => {
            'grade_list'   => [18, 17, 16, 15],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 4"
          },
          'B' => {
            'grade_list'   => [16, 15, 14, 13, 12, 11],
            'bg_color'     => 'yellow',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{job_title_degree} >= '中级'"
          }
        },
        '15' => {
          'rate'   => 5.6,
          'amount' => 7840,
          'A' => {
            'grade_list'   => [18, 17, 16, 15],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 4"
          },
          'B' => {
            'grade_list'   => [16, 15, 14, 13, 12, 11],
            'bg_color'     => 'yellow',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 5"
          }
        },
        '14' => {
          'rate'   => 5.1,
          'amount' => 7140,
          'B' => {
            'grade_list'   => [16, 15, 14, 13, 12, 11],
            'bg_color'     => 'yellow',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 4"
          },
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{education_background} >= '本科'"
          }
        },
        '13' => {
          'rate'   => 4.7,
          'amount' => 6580,
          'B' => {
            'grade_list'   => [16, 15, 14, 13, 12, 11],
            'bg_color'     => 'yellow',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 4"
          },
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 6,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 6"
          }
        },
        '12' => {
          'rate'   => 4.3,
          'amount' => 6020,
          'B' => {
            'grade_list'   => [16, 15, 14, 13, 12, 11],
            'bg_color'     => 'yellow',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 4"
          },
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 6,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 6"
          },
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{education_background} >= '大专'"
          }
        },
        '11' => {
          'rate'   => 3.9,
          'amount' => 5460,
          'B' => {
            'grade_list'   => [16, 15, 14, 13, 12, 11],
            'bg_color'     => 'yellow',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 3"
          },
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 6,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 6"
          },
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 6,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 6"
          }
        },
        '10' => {
          'rate'   => 3.6,
          'amount' => 5040,
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 4"
          },
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 6,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 6"
          }
        },
        '9' => {
          'rate'   => 3.2,
          'amount' => 4480,
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 2"
          },
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 4"
          },
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
          }
        },
        '8' => {
          'rate'   => 2.9,
          'amount' => 4060,
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 2"
          },
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 3"
          },
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '7' => {
          'rate'   => 2.6,
          'amount' => 3640,
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 1"
          },
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 3"
          },
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '6' => {
          'rate'   => 2.3,
          'amount' => 3220,
          'E' => {
            'grade_list'   => [14, 13, 12, 11, 10,9, 8, 7, 6],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 1"
          },
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 2"
          },
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '5' => {
          'rate'   => 2.1,
          'amount' => 2940,
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 2"
          },
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '4' => {
          'rate'   => 1.9,
          'amount' => 2660,
          'F' => {
            'grade_list'   => [12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 1"
          },
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        '3' => {
          'rate'   => 1.7,
          'amount' => 2380,
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        '2' => {
          'rate'   => 1.6,
          'amount' => 2240,
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        '1' => {
          'rate'   => 1.5,
          'amount' => 2100,
          'G' => {
            'grade_list'   => [9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{transfer_years} >= 1"
          }
        }
      }
    }
    Salary.create(category: 'manager12_base', table_type: 'dynamic', form_data: manager12_base)

    manager15_base = {
      'flag_list'  => ['rate','amount', 'G', 'F', 'E', 'B', 'A'],
      'flag_names' => {
        'rate'   => '系数',
        'amount' => '金额',
        'G'      => 'G',
        'F'      => 'F',
        'E'      => 'E',
        'B'      => 'B',
        'A'      => 'A',
      },
      'flags' => {
        '21' => {
          'rate'   => 9.2,
          'amount' => 12880,
          'A' => {
            'grade_list'   => [21, 20, 19, 18, 17, 16, 15],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{job_title_degree} >= '高级'"
          }
        },
        '20' => {
          'rate'   => 8.5,
          'amount' => 11900,
          'A' => {
            'grade_list'   => [21, 20, 19, 18, 17, 16, 15],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 4"
          }
        },
        '19' => {
          'rate'   => 7.8,
          'amount' => 10920,
          'A' => {
            'grade_list'   => [21, 20, 19, 18, 17, 16, 15],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 3"
          }
        },
        '18' => {
          'rate'   => 7.2,
          'amount' => 10080,
          'A' => {
            'grade_list'   => [21, 20, 19, 18, 17, 16, 15],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 2"
          },
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{job_title_degree} >= '中级'"
          }
        },
        '17' => {
          'rate'   => 6.6,
          'amount' => 9240,
          'A' => {
            'grade_list'   => [21, 20, 19, 18, 17, 16, 15],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 2"
          },
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 3"
          }
        },
        '16' => {
          'rate'   => 6.1,
          'amount' => 8540,
          'A' => {
            'grade_list'   => [21, 20, 19, 18, 17, 16, 15],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 2"
          },
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 3"
          }
        },
        '15' => {
          'rate'   => 5.6,
          'amount' => 7840,
          'A' => {
            'grade_list'   => [21, 20, 19, 18, 17, 16, 15],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{job_title_degree} >= '高级' and %{transfer_years} >= 2"
          },
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 3"
          },
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{education_background} >= '本科'"
          }
        },
        '14' => {
          'rate'   => 5.1,
          'amount' => 7140,
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 3"
          },
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 6,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 6"
          }
        },
        '13' => {
          'rate'   => 4.7,
          'amount' => 6580,
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 4"
          },
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 6,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 6"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
            "expr" => "%{education_background} >= '大专'"
          }
        },
        '12' => {
          'rate'   => 4.3,
          'amount' => 6020,
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 2"
          },
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 4"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 5"
          }
        },
        '11' => {
          'rate'   => 3.9,
          'amount' => 5460,
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 2"
          },
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 4"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 5"
          }
        },
        '10' => {
          'rate'   => 3.6,
          'amount' => 5040,
          'B' => {
            'grade_list'   => [18, 17, 16, 15, 14, 13, 12, 11, 10],
            'bg_color'     => 'grey',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{job_title_degree} >= '中级' and %{transfer_years} >= 1"
          },
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 3"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 5"
          },
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '封顶',
            'transfer_years' => 99,
          }
        },
        '9' => {
          'rate'   => 3.2,
          'amount' => 4480,
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 2"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 5"
          },
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '8' => {
          'rate'   => 2.9,
          'amount' => 4060,
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 1"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 3"
          },
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '7' => {
          'rate'   => 2.6,
          'amount' => 3640,
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 1"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 2"
          },
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        '6' => {
          'rate'   => 2.3,
          'amount' => 3220,
          'E' => {
            'grade_list'   => [15, 14, 13, 12, 11, 10, 9, 8, 7, 6],
            'bg_color'     => 'green',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{education_background} >= '本科' and %{transfer_years} >= 1"
          },
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 2"
          },
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 4,
            "expr" => "%{transfer_years} >= 4"
          }
        },
        '5' => {
          'rate'   => 2.1,
          'amount' => 2940,
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 2"
          },
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        '4' => {
          'rate'   => 1.9,
          'amount' => 2660,
          'F' => {
            'grade_list'   => [13, 12, 11, 10, 9, 8, 7, 6, 5, 4],
            'bg_color'     => 'purple',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{education_background} >= '大专' and %{transfer_years} >= 1"
          },
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        '3' => {
          'rate'   => 1.6,
          'amount' => 2380,
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        '2' => {
          'rate'   => 1.7,
          'amount' => 2240,
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        '1' => {
          'rate'   => 1.6,
          'amount' => 2100,
          'G' => {
            'grade_list'   => [10, 9, 8, 7, 6, 5, 4, 3, 2, 1],
            'bg_color'     => 'orange',
            'edit_mode'    => 'text',
            'format_cell'  => '不少于%{transfer_years}年',
            'transfer_years' => 1,
            "expr" => "%{transfer_years} >= 1"
          }
        },
      }
    }
    Salary.create(category: 'manager15_base', table_type: 'dynamic', form_data: manager15_base)

    puts "新增#{Salary.count - count}个薪酬设置"
  end

  desc "commit employees identity_name"
  task fix_identity_name: :environment do
    Employee.find_in_batches do |employees|
      employees.each do |employee|
        employee.update(identity_name: employee.name.gsub(/[a-zA-Z]/, ''))
      end
    end
  end

  desc "fix employee pcategory"
  task set_pcategory: :environment do
    duty_rank_ids = Employee::DutyRank.where(display_name: ["二正", "二副", "二副级"]).map(&:id)
    Employee.joins(:category).where("code_table_categories.display_name = ?", "干部").find_each do |employee|
      if duty_rank_ids.include? employee.duty_rank_id
        employee.update(pcategory: '基层干部')
      else
        employee.update(pcategory: '中层干部')
      end
    end

    names = %w(刘晓东 吴雄志 李航A 余晓 张科华 王显强 李威 王兴华 邹建萍 利建丽 过志宏 王竟 幸兵 赵立刚 刘余跃 王学富 曹敏 曹艳 查光忆 李光 陈建中 陈斌 邵川 张建川A 廖敏A 王飞A 曾小兰 姓名 陈焱 王辉涛 王坚 邹琳 洪波A 李宁B 蓝泉 刘钊 宋世彬 王伟松 王春雷 朱鹤鸣 薛建中 王钢A 冯军 施祖球 廖升 骆永强 王瑛 朱德宏 陈翰列 刘兴航 王飚 杜文光 江正波 卢宾 张跃生)

    Employee.where(name: names).update_all(pcategory: "主官")

    Employee.where("pcategory IS NULL").update_all(pcategory: "员工")
  end

  desc "init permission_groups"
  task permission_groups: :environment do
    pg = PermissionGroup.create(name: "部门编辑权限组")
    Permission
      .where(controller: 'departments', rw_type: 'write')
      .map(&:id).each do |item|
      pg.permission_ids << item.to_s
    end
    pg.save

    pg = PermissionGroup.create(name: "岗位权限组")
    Permission
      .where('(controller = ? AND rw_type = ?) OR (controller = ? AND rw_type = ?)', 'positions', 'write', 'specifications', 'write')
      .map(&:id).each do |item|
      pg.permission_ids << item.to_s
    end
    pg.save

    pg = PermissionGroup.create(name: "员工权限组")
    employee_edit_permissions_ids = Permission
      .where("controller like ? AND rw_type = ?", "employee%", "write")
      .map(&:id).each do |item|
      pg.permission_ids << item.to_s
    end
    pg.save


    pg = PermissionGroup.create(name: "员工自助权限组")
    Permission
      .where('(controller like ?) OR (controller = ?) OR (rw_type = ?)', 'me%', 'search_conditions', 'read')
      .map(&:id)
      .each do |item|
      pg.permission_ids << item.to_s
    end
    pg.save


    pg = PermissionGroup.create(name: '员工部门读取权限组')
   Permission.
     where('(controller like "me%") OR (controller = "search_conditions") OR (controller = "departments" AND rw_type = "read") OR (controller = "employees" AND rw_type = "read")')
     .map(&:id)
     .each do |item|
      pg.permission_ids << item.to_s
    end
    pg.save

    pg = PermissionGroup.create(name: '岗位部门读取权限组')
    Permission
      .where('(controller like "me%") OR (controller = "search_conditions") OR (controller = "departments" AND rw_type = "read") OR (controller = "positions" AND rw_type = "read")')
      .map(&:id)
      .each do |item|
      pg.permission_ids << item.to_s
    end
    pg.save
  end

  desc "fix_early_employee"
  task fix_early_employee: :environment do
    EarlyRetireEmployee.all.each do |item|
      @emp = Employee.unscoped.where(employee_no: item.employee_no).first
      @dep = Department.where(full_name: item.department).first
      @position = Position.where(name: item.position, department_id: @dep.id).first
      @emp.update(department_id: @dep.id)
      pos_params = {
        position_id: @position.id,
        category: "主职",
        sort_index: "0"
      }
      @emp.employee_positions.build(pos_params).save
    end
  end

  desc "add student allowance to flyer_science_subsidy"
  task add_student_allowance_to_flyer_science_subsidy: :environment do
    item = Salary.where(category: "flyer_science_subsidy").first
    item.form_data["student"] = 1000
    item.save
  end

  desc "import workflow state for codetable"
  task import_workflow_state_for_codetable: :environment do
    hashs = [{
        name:'actived',
        display_name:'已生效'
      },
      {
        name:'repeal',
        display_name:'已撤销'
      },
      {
        name:'rejected',
        display_name:'已驳回'
      },
      {
        name:'accepted',
        display_name:'已通过'
      },
      {
        name:'checking',
        display_name:'审批中'
      },
    ]
    hashs.each do |hash|
      CodeTable::WorkflowState.create!(hash)
    end
  end

end
