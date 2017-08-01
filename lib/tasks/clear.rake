namespace :clear do

  task educations: :environment do
    yixia = CodeTable::EducationBackground.find_or_create_by(display_name: "大专以下", level: 1)
    yixias = CodeTable::EducationBackground.where("display_name in (?)", %w(小学 初中 职高 高中 中专))
    Employee.where("education_background_id in (?)", yixias.map(&:id)).update_all(education_background_id: yixia.id)
    yixias.delete_all

    CodeTable::E.find_by(display_name: "大专").update(level: 2)

    CodeTable::EducationBackground.find_or_create_by(display_name: "非全日制本科", level: 3)

    benke = CodeTable::EducationBackground.find_by(display_name: "本科")
    benke.update(display_name: "全日制本科", level: 4) if benke

    yanjiu = CodeTable::EducationBackground.find_by(display_name: "研究生")
    yanjiu.update(level: 5) if yanjiu

    suoshi = CodeTable::EducationBackground.find_by(display_name: "硕士")
    dgree_suoshi = CodeTable::Degree.find_by(display_name: "硕士")
    Employee.where(education_background_id: suoshi.id).update_all(education_background_id: yanjiu.id, degree_id: dgree_suoshi.id)
    suoshi.delete

    boshi = CodeTable::EducationBackground.find_by(display_name: "博士")
    dgree_boshi = CodeTable::Degree.find_by(display_name: "博士")
    Employee.where(education_background_id: boshi.try(:id)).update_all(education_background_id: yanjiu.id, degree_id: dgree_boshi.id)
    boshi.delete
  end

  task degrees: :environment do
    Employee::JobTitleDegree.find_by(display_name: "初级").update(level: 1)
    Employee::JobTitleDegree.find_by(display_name: "中级").update(level: 2)
    Employee::JobTitleDegree.find_by(display_name: "高级").update(level: 3)
  end


  desc "remove no use flowrelation"
  task remove_flowrelation: :environment do
    @positions= Position.unscoped.where(id: 7916)
    FlowRelation.remove_relation(@positions)
  end

  desc "check attendance_summaries"
  task check_attendance_summaries: :environment do
    AttendanceSummaryStatusManager.where(summary_date: '2016-05').update_all(hr_department_leader_checked: true, hr_labor_relation_member_checked: true, department_leader_checked: true, department_hr_checked: true)
  end

  task role_menus: :environment do
    FlowRelation.roles.each do |role|
      level = 99
      case role
      when 'company_leader'
        level = 1
      when 'hr_leader'
        level = 2
      when 'department_hr'
        level = 3
      when 'department_leader'
        level = 4
      else
      end

      role_menu = RoleMenu.find_or_create_by(role_name: role)
      role_menu.update(level: level)
    end
  end

  desc "update global config"
  task fix_global_config: :environment do
    config = Salary.find_by(category: 'global')
    config.form_data['insurance_proxy']        = config.form_data.delete("air_accident_bonus")
    config.form_data['cabin_grow_up']          = config.form_data.delete('upgrades_bonus')
    config.form_data['full_sale_promotion']    = config.form_data.delete('promotions_bonus')
    config.form_data['article_fee']            = config.form_data.delete('royalties_bonus')
    config.form_data['all_right_fly']          = config.form_data.delete('no_error_bonus')
    config.form_data['year_composite_bonus']   = config.form_data.delete('yearly_composite_bonus')
    config.form_data['move_perfect']           = config.form_data.delete('transport_bonus')
    config.form_data['security_special']       = config.form_data.delete('safe_special_bonus')
    config.form_data['dep_security_undertake'] = config.form_data.delete('safe_manage_bonus')
    config.form_data['fly_star']               = config.form_data.delete('fly_safe_bonus')
    config.form_data['year_all_right_fly']     = config.form_data.delete('yearly_fix_bonus')
    config.form_data.delete('network_connect')
    config.form_data['passenger_quarter_fee'] = config.form_data.delete('quarter_fee')
    config.form_data['freight_quality_fee'] = config.form_data['passenger_quarter_fee']
    config.save
  end

  task department_nature: :environment do
    CodeTable::DepartmentNature.all.each do |nature|
      case nature.display_name
      when "机关部门"
        level = 3
      when "生产部门"
        level = 2
      when "分公司基地"
        level = 1
      else
        level = 0
      end

      nature.update(level: level)
    end
  end

  task permission_groups: :environment do
    FlowRelation.roles.each do |role|
      PermissionGroup.find_or_create_by(name: role, permission_ids: [Permission.first.id])
    end
  end

  task unused_roles: :environment do
    roles = %w(flight_member it_director it_chairman)

    FlowRelation.where("role_name in (?)", roles).delete_all
    RoleMenu.where("role_name in (?)", roles).delete_all
    PermissionGroup.where("name in (?)", roles).delete_all
  end

  task salary_other: :environment do
    form_data2 = {
      "flag_list" => ["rate", "amount", "A", "B", "C", "D"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D"
      },
      "flags" => {
        "20" => {
          "rate" => 9.3,
          "amount" => 13020
        },
        "19" => {
          "rate" => 8.7,
          "amount" => 12180
        },
        "18" => {
          "rate" => 7.8,
          "amount" => 10920
        },
        "17" => {
          "rate" => 7.3,
          "amount" => 10220
        },
        "16" => {
          "rate" => 6.8,
          "amount" => 9520
        },
        "15" => {
          "rate" => 6.5,
          "amount" => 9100
        },
        "14" => {
          "rate" => 6.2,
          "amount" => 8680
        },
        "13" => {
          "rate" => 5.9,
          "amount" => 8260,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 8,
            "expr" => "%{transfer_years} >= 8"
          }
        },
        "12" => {
          "rate" => 5.6,
          "amount" => 7840,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 8,
            "expr" => "%{transfer_years} >= 8"
          }
        },
        "11" => {
          "rate" => 5.3,
          "amount" => 7420,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 8,
            "expr" => "%{transfer_years} >= 8"
          }
        },
        "10" => {
          "rate" => 4.9,
          "amount" => 6860,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        "9" => {
          "rate" => 4.5,
          "amount" => 6300,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        "8" => {
          "rate" => 4.1,
          "amount" => 5740,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        "7" => {
          "rate" => 3.8,
          "amount" => 5320,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "6" => {
          "rate" => 3.4,
          "amount" => 4760,
          "A" => {
            "grade_list" => [6, 7, 8, 9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "5" => {
          "rate" => 3,
          "amount" => 4200,
          "B" => {
            "grade_list" => [5, 6, 7, 8, 9, 10, 11, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "4" => {
          "rate" => 2.5,
          "amount" => 3500,
          "C" => {
            "grade_list" => [4, 5, 6, 7, 8, 9, 10, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "3" => {
          "rate" => 2,
          "amount" => 2800,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1.5,
            "expr" => "%{transfer_years} >= 1.5"
          }
        },
        "2" => {
          "rate" => 1.5,
          "amount" => 2100,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.5,
            "expr" => "%{transfer_years} >= 0.5"
          }
        },
        "1" => {
          "rate" => 1,
          "amount" => 1400,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} >= 0.25"
          }
        }
      }
    }

    Salary.find_or_create_by(category: 'service_normal_perf', table_type: 'dynamic').update(form_data: form_data2)

    %w(manage_market_perf airline_business_perf information_perf service_c_1_perf service_c_2_perf service_c_3_perf service_c_driving_perf).each do |category|
      salary = Salary.find_by(category: category)
      if salary
        form_data = salary.form_data
        form_data["flag_list"].delete("E")
        form_data["flag_list"] << "D" if form_data["flag_list"].exclude?("D")
        form_data["flag_names"].delete("E")
        form_data["flag_names"]["D"] = "D" if form_data["flag_names"]["D"].blank?
        form_data["flags"].each do |k, v|
          form_data["flags"][k].delete("D") if v["D"].present?
          if v["E"].present?
            form_data["flags"][k]["D"] = form_data["flags"][k]["E"]
            form_data["flags"][k].delete("E")
          end
        end
        salary.update(form_data: form_data)
      end
    end
  end

  task salary: :environment do
    form_data2 = {
      "flag_list" => ["rate", "amount", "B1", "B2", "C1", "C2", "C3", "C4", "C5", "D1", "D2", "D3", "D4"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "B1" => "B1",
        "B2" => "B2",
        "C1" => "C1",
        "C2" => "C2",
        "C3" => "C3",
        "C4" => "C4",
        "C5" => "C5",
        "D1" => "D1",
        "D2" => "D2",
        "D3" => "D3",
        "D4" => "D4"
      },
      "flags" => {
        "21" => {
          "rate" => 17.5,
          "amount" => 24500,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "荣誉级",
            "transfer_years" => 999
          }
        },
        "20" => {
          "rate" => 16.1,
          "amount" => 22540,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "19" => {
          "rate" => 13.6,
          "amount" => 19040,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 4,
            "expr" => "%{transfer_years} >= 4"
          }
        },
        "18" => {
          "rate" => 12.3,
          "amount" => 17220,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "B2" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          },
          "C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "17" => {
          "rate" => 11.0,
          "amount" => 15400,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "B2" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "16" => {
          "rate" => 10.0,
          "amount" => 14000,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "B2" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "15" => {
          "rate" => 9.2,
          "amount" => 12880,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "B2" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "14" => {
          "rate" => 8.5,
          "amount" => 11900,
          "B2" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "13" => {
          "rate" => 7.8,
          "amount" => 10920,
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "12" => {
          "rate" => 7.2,
          "amount" => 10080,
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "11" => {
          "rate" => 6.6,
          "amount" => 9240,
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "10" => {
          "rate" => 6.1,
          "amount" => 8540,
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "封顶",
            "transfer_years" => 99
          }
        },
        "9" => {
          "rate" => 5.6,
          "amount" => 7840,
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "8" => {
          "rate" => 5.1,
          "amount" => 7140,
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "7" => {
          "rate" => 4.7,
          "amount" => 6580,
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          }
        },
        "6" => {
          "rate" => 4.3,
          "amount" => 6020,
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          }
        }
      }
    }

    Salary.find_by(category: 'leader_base', table_type: 'dynamic').update(form_data: form_data2)

    information_perf = {
      "flag_list" => ["rate", "amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "rate" => 1.5,
          "amount" => 2100,
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "rate" => 2,
          "amount" => 2800,
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{performance} == '待改进' and %{transfer_years} < 10"
          },
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.5,
            "expr" => "%{transfer_years} > 0.5"
          }
        },
        "3" => {
          "rate" => 2.5,
          "amount" => 3500,
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1.5,
            "expr" => "%{transfer_years} > 1.5"
          }
        },
        "4" => {
          "rate" => 2.8,
          "amount" => 3920,
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 2"
          }
        },
        "5" => {
          "rate" => 3.1,
          "amount" => 4340,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 2"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 3"
          },
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "6" => {
          "rate" => 3.4,
          "amount" => 4760,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 2"
          },
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 3"
          }
        },
        "7" => {
          "rate" => 3.7,
          "amount" => 5180,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 5"
          }
        },
        "8" => {
          "rate" => 4,
          "amount" => 5600,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 5"
          }
        },
        "9" => {
          "rate" => 4.3,
          "amount" => 6020,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 8"
          }
        },
        "10" => {
          "rate" => 4.6,
          "amount" => 6440,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 8"
          }
        },
        "11" => {
          "rate" => 4.9,
          "amount" => 6860,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 8"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于8年 并且 学历不低于本科",
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 8 and %{education_background} >= '本科'"
          }
        },
        "12" => {
          "rate" => 5.2,
          "amount" => 7280
        },
        "13" => {
          "rate" => 5.5,
          "amount" => 7700,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于8年 并且 （学历不低于本科 或 职称级别不低于中级）",
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 8 and ( %{education_background} >= '本科' or %{job_title_degree} >= '中级' )"
          }
        },
        "14" => {
          "rate" => 6,
          "amount" => 8400
        },
        "15" => {
          "rate" => 6.5,
          "amount" => 9100,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于8年 并且 职称级别不低于中级",
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 8 and %{job_title_degree} >= '中级'"
          }
        },
        "16" => {
          "rate" => 7.4,
          "amount" => 10360
        },
        "17" => {
          "rate" => 8,
          "amount" => 11200
        },
        "18" => {
          "rate" => 8.5,
          "amount" => 11900
        },
        "19" => {
          "rate" => 9.3,
          "amount" => 13020
        }
      }
    }

    Salary.find_by(category: 'information_perf', table_type: 'dynamic').update(form_data: information_perf)

    airline_business_perf = {
      "flag_list" => ["rate", "amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "rate" => 1,
          "amount" => 1400,
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "rate" => 1.5,
          "amount" => 2100,
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{performance} == '待改进' and %{transfer_years} < 10"
          },
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.5,
            "expr" => "%{transfer_years} > 0.5"
          }
        },
        "3" => {
          "rate" => 2,
          "amount" => 2800,
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1.5,
            "expr" => "%{transfer_years} > 1.5"
          }
        },
        "4" => {
          "rate" => 2.5,
          "amount" => 3500,
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 2"
          }
        },
        "5" => {
          "rate" => 2.9,
          "amount" => 4060,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 2"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 3"
          },
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "6" => {
          "rate" => 3.3,
          "amount" => 4620,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 2"
          },
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 3"
          }
        },
        "7" => {
          "rate" => 3.7,
          "amount" => 5180,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 5"
          }
        },
        "8" => {
          "rate" => 4,
          "amount" => 5600,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 5"
          }
        },
        "9" => {
          "rate" => 4.3,
          "amount" => 6020,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 8"
          }
        },
        "10" => {
          "rate" => 4.6,
          "amount" => 6440,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 8"
          }
        },
        "11" => {
          "rate" => 4.9,
          "amount" => 6860,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 8"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于8年 并且 学历不低于本科",
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 8 and %{education_background} >= '本科'"
          }
        },
        "12" => {
          "rate" => 5.2,
          "amount" => 7280
        },
        "13" => {
          "rate" => 5.5,
          "amount" => 7700,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于8年 并且 （学历不低于本科 或 职称级别不低于中级）",
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 8 and ( %{education_background} >= '本科' or %{job_title_degree} >= '中级' )"
          }
        },
        "14" => {
          "rate" => 6,
          "amount" => 8400
        },
        "15" => {
          "rate" => 6.5,
          "amount" => 9100,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于8年 并且 职称级别不低于中级",
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 8 and %{job_title_degree} >= '中级'"
          }
        },
        "16" => {
          "rate" => 7.4,
          "amount" => 10360
        },
        "17" => {
          "rate" => 8,
          "amount" => 11200
        },
        "18" => {
          "rate" => 8.5,
          "amount" => 11900
        },
        "19" => {
          "rate" => 9.3,
          "amount" => 13020
        }
      }
    }

    Salary.find_by(category: 'airline_business_perf', table_type: 'dynamic').update(form_data: airline_business_perf)


      manage_market_perf = {
      "flag_list" => ["rate", "amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "rate" => 1,
          "amount" => 1400,
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "rate" => 1.5,
          "amount" => 2100,
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{performance} == '待改进' and %{transfer_years} < 10"
          },
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.5,
            "expr" => "%{transfer_years} > 0.5"
          }
        },
        "3" => {
          "rate" => 2,
          "amount" => 2800,
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1.5,
            "expr" => "%{transfer_years} > 1.5"
          }
        },
        "4" => {
          "rate" => 2.5,
          "amount" => 3500,
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 2"
          }
        },
        "5" => {
          "rate" => 2.8,
          "amount" => 3920,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 14],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 2"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 3"
          },
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "6" => {
          "rate" => 3.1,
          "amount" => 4340,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15, 18],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 2"
          },
          "B" => {
            "grade_list" => [5, 6, 8, 10, 14],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 3"
          }
        },
        "7" => {
          "rate" => 3.4,
          "amount" => 4760,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15, 18],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 5"
          }
        },
        "8" => {
          "rate" => 3.7,
          "amount" => 5180,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 14],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 5"
          }
        },
        "9" => {
          "rate" => 4,
          "amount" => 5600,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15, 18],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于8年 并且 职称级别不低于中级",
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 8 and %{job_title_degree} >= '中级'"
          }
        },
        "10" => {
          "rate" => 4.3,
          "amount" => 6020,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 14],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 8"
          }
        },
        "11" => {
          "rate" => 4.6,
          "amount" => 6440,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15, 18],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 8"
          }
        },
        "12" => {
          "rate" => 4.9,
          "amount" => 6860,
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",
            "edit_mode" => "dialog",
            "format_cell" => "不少于15年 并且 职称级别不低于中级",
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 15 and %{job_title_degree} >= '中级'"
          }
        },
        "13" => {
          "rate" => 5.2,
          "amount" => 7280
        },
        "14" => {
          "rate" => 5.6,
          "amount" => 7840,
          "B" => {
            "grade_list" => [5, 6, 8, 10, 14],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于15年 并且 职称级别不低于中级",
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 15 and %{job_title_degree} >= '中级'"
          }
        },
        "15" => {
          "rate" => 6,
          "amount" => 8400,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15, 18],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于15年 并且 职称级别不低于中级",
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 15 and %{job_title_degree} >= '中级'"
          }
        },
        "16" => {
          "rate" => 7,
          "amount" => 9800
        },
        "17" => {
          "rate" => 7.5,
          "amount" => 10500
        },
        "18" => {
          "rate" => 8,
          "amount" => 11200,
          "A" => {
            "grade_list" => [6, 7, 9, 11, 15, 18],
            "bg_color" => "yellow",
            "edit_mode" => "dialog",
            "format_cell" => "不少于15年 并且 职称级别不低于高级",
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 15 and %{job_title_degree} >= '高级'"
          }
        },
        "19" => {
          "rate" => 8.7,
          "amount" => 12180
        }
      }
    }

    Salary.find_by(category: 'manage_market_perf', table_type: 'dynamic').update(form_data: manage_market_perf)

    manager12_base = Salary.find_by(category: 'manager12_base', table_type: 'dynamic')
    manager12_base.form_data['flag_names']['G'] = 'G'
    manager12_base.save

    manager15_base = Salary.find_by(category: 'manager15_base', table_type: 'dynamic')
    manager15_base.form_data['flag_names']['G'] = 'G'
    manager15_base.save

    service_b_normal_cleaner_base = Salary.find_by(category: 'service_b_normal_cleaner_base')
    service_b_normal_cleaner_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_normal_cleaner_base.save

    service_b_parking_cleaner_base = Salary.find_by(category: 'service_b_parking_cleaner_base')
    service_b_parking_cleaner_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_parking_cleaner_base.save

    service_b_hotel_service_base = Salary.find_by(category: 'service_b_hotel_service_base')
    service_b_hotel_service_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_hotel_service_base.save

    service_b_green_base = Salary.find_by(category: 'service_b_green_base')
    service_b_green_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_green_base.save

    service_b_front_desk_base = Salary.find_by(category: 'service_b_front_desk_base')
    service_b_front_desk_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_front_desk_base.save

    service_b_security_guard_base = Salary.find_by(category: 'service_b_security_guard_base')
    service_b_security_guard_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_security_guard_base.save

    service_b_input_base = Salary.find_by(category: 'service_b_input_base')
    service_b_input_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_input_base.save

    service_b_guard_leader1_base = Salary.find_by(category: 'service_b_guard_leader1_base')
    service_b_guard_leader1_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_guard_leader1_base.save

    service_b_device_keeper_base = Salary.find_by(category: 'service_b_device_keeper_base')
    service_b_device_keeper_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_device_keeper_base.save

    service_b_unloading_base = Salary.find_by(category: 'service_b_unloading_base')
    service_b_unloading_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_unloading_base.save

    service_b_making_water_base = Salary.find_by(category: 'service_b_making_water_base')
    service_b_making_water_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_making_water_base.save

    service_b_add_water_base = Salary.find_by(category: 'service_b_add_water_base')
    service_b_add_water_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_add_water_base.save

    service_b_guard_leader2_base = Salary.find_by(category: 'service_b_guard_leader2_base')
    service_b_guard_leader2_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_guard_leader2_base.save

    service_b_water_light_base = Salary.find_by(category: 'service_b_water_light_base')
    service_b_water_light_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_water_light_base.save

    service_b_car_repair_base = Salary.find_by(category: 'service_b_car_repair_base')
    service_b_car_repair_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_car_repair_base.save

    service_b_airline_keeper_base = Salary.find_by(category: 'service_b_airline_keeper_base')
    service_b_airline_keeper_base.form_data['flag_names'] = {
      'amount' => '金额',
      'A' => 'A'
    }
    service_b_airline_keeper_base.save

    air_observer_base = Salary.find_by(category: 'air_observer_base', table_type: 'dynamic')
    air_observer_base.form_data['flag_names']['X'] = 'X'
    air_observer_base.save

    front_run_base = Salary.find_by(category: 'front_run_base', table_type: 'dynamic')
    front_run_base.form_data['flag_names']['X'] = 'X'
    front_run_base.save

    service_c_1_perf = Salary.find_by(category: 'service_c_1_perf', table_type: 'dynamic')
    service_c_1_perf.form_data = {
      "flag_list" => ["amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "amount" => "服务C-1",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "amount" => 1950,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "amount" => 2200,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} > 1"
          }
        },
        "3" => {
          "amount" => 2500,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "4" => {
          "amount" => 2750,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          }
        },
        "5" => {
          "amount" => 3000,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "6" => {
          "amount" => 3200
        },
        "7" => {
          "amount" => 3400,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "8" => {
          "amount" => 3600,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "9" => {
          "amount" => 3800,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 18,
            "expr" => "%{transfer_years} > 18"
          }
        },
        "10" => {
          "amount" => 4000,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "11" => {
          "amount" => 4200,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "12" => {
          "amount" => 4600
        }
      }
    }
    service_c_1_perf.save

    service_c_2_perf = Salary.find_by(category: 'service_c_2_perf', table_type: 'dynamic')
    service_c_2_perf.form_data = {
      "flag_list" => ["amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "amount" => "服务C-2",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "amount" => 1800,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "amount" => 2050,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} > 1"
          }
        },
        "3" => {
          "amount" => 2300,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "4" => {
          "amount" => 2550,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          }
        },
        "5" => {
          "amount" => 2800,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "6" => {
          "amount" => 3000
        },
        "7" => {
          "amount" => 3200,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "8" => {
          "amount" => 3400,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "9" => {
          "amount" => 3550,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 18,
            "expr" => "%{transfer_years} > 18"
          }
        },
        "10" => {
          "amount" => 3700,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "11" => {
          "amount" => 4000,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "12" => {
          "amount" => 4200
        }
      }
    }
    service_c_2_perf.save

    service_c_3_perf = Salary.find_by(category: 'service_c_3_perf', table_type: 'dynamic')
    service_c_3_perf.form_data = {
      "flag_list" => ["amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "amount" => "服务C-3",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "amount" => 1650,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "amount" => 1900,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} > 1"
          }
        },
        "3" => {
          "amount" => 2150,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "4" => {
          "amount" => 2400,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          }
        },
        "5" => {
          "amount" => 2600,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "6" => {
          "amount" => 2700
        },
        "7" => {
          "amount" => 2800,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "8" => {
          "amount" => 3000,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "9" => {
          "amount" => 3100,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 18,
            "expr" => "%{transfer_years} > 18"
          }
        },
        "10" => {
          "amount" => 3200,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "11" => {
          "amount" => 3400,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "12" => {
          "amount" => 3600
        }
      }
    }
    service_c_3_perf.save

    service_c_driving_perf = Salary.find_by(category: 'service_c_driving_perf', table_type: 'dynamic')
    service_c_driving_perf.form_data = {
      "flag_list" => ["amount", "A", "B", "C", "D", "E"],
      "flag_names" => {
        "amount" => "服务C-驾驶",
        "A" => "A",
        "B" => "B",
        "C" => "C",
        "D" => "D",
        "E" => "E"
      },
      "flags" => {
        "1" => {
          "amount" => 1700,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 0.25,
            "expr" => "%{transfer_years} > 0.25"
          }
        },
        "2" => {
          "amount" => 1850,
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "到岗满 %{transfer_years} 年的次月起",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} > 1"
          }
        },
        "3" => {
          "amount" => 2000,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} >= 10"
          }
        },
        "4" => {
          "amount" => 2300,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          }
        },
        "5" => {
          "amount" => 2400,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "6" => {
          "amount" => 2500
        },
        "7" => {
          "amount" => 2700,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "8" => {
          "amount" => 2800,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          }
        },
        "9" => {
          "amount" => 2900,
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 18,
            "expr" => "%{transfer_years} > 18"
          }
        },
        "10" => {
          "amount" => 3000,
          "B" => {
            "grade_list" => [4, 7, 10],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "11" => {
          "amount" => 3200,
          "A" => {
            "grade_list" => [5, 8, 11],
            "bg_color" => "white",
            "edit_mode" => "dialog",
            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{transfer_years} > 10"
          }
        },
        "12" => {
          "amount" => 3400
        },
        "13" => {
          "amount" => 3800
        }
      }
    }
    service_c_driving_perf.save

  end

  task schedule: :environment do
    %w(标准工作时 标准工作制).each do |name|
      CodeTable::Schedule.find_by(name: name).destroy
    end
  end

  task performances: :environment do
    Performance.where.not(category: nil).each do |per|
      category_name = nil
      case per.category
      when 'year'
        category_name = '年度'
      when 'month'
        category_name = '月度'
      when 'season'
        category_name = '季度'
      end
      per.update(category_name: category_name)
    end
  end

  task fix_summary_date: :environment do
    AttendanceSummaryStatusManager.find_each do |status_manager|
      AttendanceSummary.transaction do
        status_manager.attendance_summaries.find_each do |record|
          record.update!(summary_date: status_manager.summary_date)
        end
      end
    end
  end

  desc 'clear repeat contract'
  task clear_contract: :environment do
    Contract.where(original: true).each do |item|
      array = Contract.where(
        original: true,
        employee_id: item.employee_id,
        change_flag: item.change_flag,
        start_date: item.start_date,
        end_date: item.end_date
      ).order(:created_at)

      array.each_with_index do |item, index|
        item.destroy if index > 0
      end
    end
  end

  desc "clear edu chagne record"
  task clean_edu: :environment do
    employee = Employee.where(employee_no: "000950").first
    EducationExperienceRecord.where(employee_id: employee.id).last.destroy if EducationExperienceRecord.where(employee_id: employee.id).present?
    Employee::EducationExperience.where(employee_id: employee.id).last.destroy if Employee::EducationExperience.where(employee_id: employee.id).present?
  end


  desc "clear position_records position_change_records"
  task clear_position_error_data: :environment do
    Employee.where(employee_no: [ "008851", "007828", "007980", "003975", "001467", "003036", "014153", "003244" ]).each do |employee|
      employee.position_change_records.destroy_all
      employee.position_records.destroy_all
    end

    e = Employee.find 30936
    e.reduce_year_days(1)

    e = Employee.find 30917
    e.reduce_year_days(5, "2015")
  end
end
