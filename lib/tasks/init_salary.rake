namespace  :init do
  desc 'init salary'
  task salary: :environment do
    count = Salary.count

    form_data1 = {
      "dollar_rate" => 6.12345,             #float, 美元汇率
      "minimum_wage" => 1200.00,            #float, 最低工资
      "average_wage" => 2400.00,            #float, 平均工资
      "basic_cardinality" => 1400,   #integer, 薪酬基数(基本工资)
      "coefficient" => {  #月度绩效系数
          "2015-06" => {
              "company" => 500,               #integer, 公司
              "business_council" => 400,      #integer, 商委
              "logistics" => 300              #integer, 物流
          },
          "2015-07" => {
              "company" => 500,               #integer, 公司
              "business_council" => 400,      #integer, 商委
              "logistics" => 300              #integer, 物流
          }
      }
    }

    Salary.create(category: 'global', table_type: 'static', form_data: form_data1)

    form_data2 = {
      "flag_list" => ["rate", "amount", "B1", "B2/C1", "C2", "C3", "C4", "C5", "D1", "D2", "D3", "D4"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "B1" => "B1",
        "B2/C1" => "B2/C1",
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

            "format_cell" => "荣誉级",
            "transfer_years" => 999,
            "expr" => "transfer_years == 999"
          }
        },
        "20" => {
          "rate" => 16.1,
          "amount" => 22540,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "19" => {
          "rate" => 13.6,
          "amount" => 19040,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",

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

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "B2/C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "17" => {
          "rate" => 11.0,
          "amount" => 15400,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "B2/C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "16" => {
          "rate" => 10.0,
          "amount" => 14000,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "B2/C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "15" => {
          "rate" => 9.2,
          "amount" => 12880,
          "B1" => {
            "grade_list" => [15, 16, 17, 18, 19, 20, 21],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "B2/C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "14" => {
          "rate" => 8.5,
          "amount" => 11900,
          "B2/C1" => {
            "grade_list" => [14, 15, 16, 17, 18],
            "bg_color" => "grey",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "13" => {
          "rate" => 7.8,
          "amount" => 10920,
          "C2" => {
            "grade_list" => [13, 14, 15, 16, 17],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "12" => {
          "rate" => 7.2,
          "amount" => 10080,
          "C3" => {
            "grade_list" => [12, 13, 14, 15, 16],
            "bg_color" => "cyan",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "11" => {
          "rate" => 6.6,
          "amount" => 9240,
          "C4" => {
            "grade_list" => [11, 12, 13, 14, 15],
            "bg_color" => "yellow",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "10" => {
          "rate" => 6.1,
          "amount" => 8540,
          "C5" => {
            "grade_list" => [10, 11, 12, 13, 14],
            "bg_color" => "purple",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "9" => {
          "rate" => 5.6,
          "amount" => 7840,
          "D1" => {
            "grade_list" => [9, 10, 11, 12, 13],
            "bg_color" => "green",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D2" => {
            "grade_list" => [8, 9, 10, 11, 12],
            "bg_color" => "red",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",

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

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D3" => {
            "grade_list" => [7, 8, 9, 10, 11],
            "bg_color" => "purple",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",

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

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          },
          "D4" => {
            "grade_list" => [6, 7, 8, 9, 10],
            "bg_color" => "yellow",

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

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          }
        }
      }
    }

    Salary.create(category: 'leader_base', table_type: 'dynamic', form_data: form_data2)

    air_steward_base = {
      "flag_list" => ["amount", "condition"],
      "flag_names" => {
        "amount" => "标准",
        "X" => "X"
      },
      "flags" => {
        "14" => {
          "amount" => 6350,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "荣誉档",
            "transfer_years" => 999
          }
        },
        "13" => {
          "amount" => 5900,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 25,
            "expr" => "%{transfer_years} >= 25"
          }
        },
        "12" => {
          "amount" => 5500,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 20,
            "expr" => "%{transfer_years} >= 20"
          }
        },
        "11" => {
          "amount" => 5200,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 17,
            "expr" => "%{transfer_years} >= 17"
          }
        },
        "10" => {
          "amount" => 4900,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 14,
            "expr" => "%{transfer_years} >= 14"
          }
        },
        "9" => {
          "amount" => 4600,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 11,
            "expr" => "%{transfer_years} >= 11"
          }
        },
        "8" => {
          "amount" => 4300,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 9,
            "expr" => "%{transfer_years} >= 9"
          }
        },
        "7" => {
          "amount" => 4000,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 7,
            "expr" => "%{transfer_years} >= 7"
          }
        },
        "6" => {
          "amount" => 3700,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          }
        },
        "5" => {
          "amount" => 3300,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 4,
            "expr" => "%{transfer_years} >= 4"
          }
        },
        "4" => {
          "amount" => 2900,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "3" => {
          "amount" => 2500,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "2" => {
          "amount" => 2200,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "本企业连续服务不少于%{transfer_years}年",
            "transfer_years" => 1,
            "expr" => "%{transfer_years} >= 1"
          }
        },
        "1" => {
          "amount" => 1800,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12, 13, 14],
            "bg_color" => "white",
            "format_cell" => "新进",
            "transfer_years" => 0
          }
        }
      }
    }

    Salary.create(category: 'air_steward_base', table_type: 'dynamic', form_data: air_steward_base)

    observer_and_front1 = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "空中观察员"
      },
      "flags" => {
        "13" => {
          "rate" => 7.8,
          "amount" => 10920,
          "X" => {
            "grade_list" => [8, 9, 10, 11, 12, 13],
            "bg_color" => "white",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "12" => {
          "rate" => 7.2,
          "amount" => 10080,
          "X" => {
            "grade_list" => [8, 9, 10, 11, 12, 13],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "11" => {
          "rate" => 6.6,
          "amount" => 9240,
          "X" => {
            "grade_list" => [8, 9, 10, 11, 12, 13],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "10" => {
          "rate" => 6.1,
          "amount" => 8540,
          "X" => {
            "grade_list" => [8, 9, 10, 11, 12, 13],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "9" => {
          "rate" => 5.6,
          "amount" => 7840,
          "X" => {
            "grade_list" => [8, 9, 10, 11, 12, 13],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "8" => {
          "rate" => 5.1,
          "amount" => 7140,
          "X" => {
            "grade_list" => [8, 9, 10, 11, 12, 13],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        }
      }
    }

    observer_and_front2 = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "前场运行"
      },
      "flags" => {
        "13" => {
          "rate" => 7.2,
          "amount" => 10080,
          "X" => {
            "grade_list" => [7, 8, 9, 10, 11, 12],
            "bg_color" => "white",

            "format_cell" => "封顶",
            "transfer_years" => 99,
            "expr" => "transfer_years == 99"
          }
        },
        "12" => {
          "rate" => 6.6,
          "amount" => 9240,
          "X" => {
            "grade_list" => [7, 8, 9, 10, 11, 12],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "11" => {
          "rate" => 6.1,
          "amount" => 8540,
          "X" => {
            "grade_list" => [7, 8, 9, 10, 11, 12],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 3,
            "expr" => "%{transfer_years} >= 3"
          }
        },
        "10" => {
          "rate" => 5.6,
          "amount" => 7840,
          "X" => {
            "grade_list" => [7, 8, 9, 10, 11, 12],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "9" => {
          "rate" => 5.1,
          "amount" => 7140,
          "X" => {
            "grade_list" => [7, 8, 9, 10, 11, 12],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "8" => {
          "rate" => 4.7,
          "amount" => 6580,
          "X" => {
            "grade_list" => [7, 8, 9, 10, 11, 12],
            "bg_color" => "white",

            "format_cell" => "%{transfer_years}年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        }
      }
    }

    Salary.create(category: 'air_observer_base', table_type: 'dynamic', form_data: observer_and_front1)
    Salary.create(category: 'front_run_base', table_type: 'dynamic', form_data: observer_and_front2)

    flyer_student_base = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "默认"
      },
      "flags" => {
        "1" => {
          "rate" => 1.8,
          "amount" => 2520,
          "X" => {
            "grade_list" => [1],
            "bg_color" => "white",

            "format_cell" => "接收飞行员报道进入学员队",
            "transfer_years" => 0
          }
        }
      }
    }

    Salary.create(category: 'flyer_student_base', table_type: 'dynamic', form_data: flyer_student_base)

    flyer_leader_base = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "默认"
      },
      "flags" => {
        "1" => {
          "rate" => 14.6,
          "amount" => 10360,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间18年以上;2、在本公司飞行时间20000小时以上;3、晋升前连续 10 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 6 年无航空安全严重差错;5、具备高原、特殊机场飞行运行资格。",
            "expr" => "%{drive_work_value} >= 18 and %{fly_time_value} >= 20000"
          }
        },
        "2" => {
          "rate" => 13.8,
          "amount" => 9520,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间16年以上;2、在本公司飞行时间16000小时以上;3、晋升前连续 8 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 5 年无航空安全严重差错;5、具备高原、特殊机场飞行运行资格。",
            "expr" => "%{drive_work_value} >= 16 and %{fly_time_value} >= 16000"
          }
        },
        "3" => {
          "rate" => 13,
          "amount" => 8680,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间14年以上;2、在本公司飞行时间14000小时以上;3、晋升前连续 7 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 4 年无航空安全严重差错;5、具备高原、特殊机场飞行运行资格。",
            "expr" => "%{drive_work_value} >= 14 and %{fly_time_value} >= 14000"
          }
        },
        "4" => {
          "rate" => 12.2,
          "amount" => 7840,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间12年以上;2、在本公司飞行时间12000小时以上;3、晋升前连续 6 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 3 年无航空安全严重差错。",
            "expr" => "%{drive_work_value} >= 12 and %{fly_time_value} >= 12000"
          }
        },
        "5" => {
          "rate" => 11.4,
          "amount" => 7000,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间10年以上;2、在本公司飞行时间11000小时以上;3、晋升前连续 3 年无人为原因飞行事故征候及以上不良安全记录。",
            "expr" => "%{drive_work_value} >= 10 and %{fly_time_value} >= 11000"
          }
        },
        "6" => {
          "rate" => 10.6,
          "amount" => 6300,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间8年以上;2、在本公司飞行时间10000小时以上;3、晋升前连续 3 年无人为原因飞行事故征候及以上不良安全记录。",
            "expr" => "%{drive_work_value} >= 8 and %{fly_time_value} >= 10000"
          }
        },
        "7" => {
          "rate" => 9.8,
          "amount" => 5600,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间6年以上;2、在本公司飞行时间8000小时以上;3、晋升前连续 2 年无人为原因飞行事故征候及以上不良安全记录。",
            "expr" => "%{drive_work_value} >= 6 and %{fly_time_value} >= 8000"
          }
        },
        "8" => {
          "rate" => 9,
          "amount" => 4900,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间4年以上;2、在本公司飞行时间6000小时以上;3、晋升前连续 1 年无人为原因飞行事故征候及以上不良安全记录。",
            "expr" => "%{drive_work_value} >= 4 and %{fly_time_value} >= 6000"
          }
        },
        "9" => {
          "rate" => 8.2,
          "amount" => 4200,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "1、现任责任机长,现有机型责任机长经历时间2年以上;2、在本公司飞行时间4000小时以上;3、晋升前连续 1 年无人为原因飞行事故征候及以上不良安全记录。",
            "expr" => "%{drive_work_value} >= 2 and %{fly_time_value} >= 4000"
          }
        },
        "10" => {
          "rate" => 7.4,
          "amount" => 3400,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            "bg_color" => "white",

            "format_cell" => "聘为责任机长",
            "drive_work_value" => 0,
            "fly_time_value" => 0
          }
        }
      }
    }

    Salary.create(category: 'flyer_leader_base', table_type: 'dynamic', form_data: flyer_leader_base)

    flyer_teacher_C_base = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "默认"
      },
      "flags" => {
        "1" => {
          "rate" => 15.4,
          "amount" => 21560,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 C 类飞行教员,现有机型教员经历时间12年以上;2、在本公司飞行时间15000小时以上;3、晋升前连续 8 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 5 年无航空安全严重差错;5、具备高原、特殊机场飞行运行资格。",
            "expr" => "%{drive_work_value} >= 12 and %{fly_time_value} >= 15000"
          }
        },
        "2" => {
          "rate" => 14.6,
          "amount" => 20440,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 C 类飞行教员,现有机型教员经历时间8年以上;2、在本公司飞行时间12000小时以上;3、晋升前连续 5 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 3 年无航空安全严重差错;5、具备高原、特殊机场飞行运行资格。",
            "expr" => "%{drive_work_value} >= 8 and %{fly_time_value} >= 12000"
          }
        },
        "3" => {
          "rate" => 13.8,
          "amount" => 19320,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 C 类飞行教员,现有机型教员经历时间4年以上;2、在本公司飞行时间8000小时以上;3、晋升前连续 3 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 1 年无航空安全严重差错;5、具备高原、特殊机场飞行运行资格。",
            "expr" => "%{drive_work_value} >= 4 and %{fly_time_value} >= 8000"
          }
        },
        "4" => {
          "rate" => 13,
          "amount" => 18200,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "现任 C 类飞行教员。",
            "drive_work_value" => 0,
            "fly_time_value" => 0
          }
        }
      }
    }

    Salary.create(category: 'flyer_teacher_C_base', table_type: 'dynamic', form_data: flyer_teacher_C_base)

    flyer_teacher_B_base = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "默认"
      },
      "flags" => {
        "1" => {
          "rate" => 13.8,
          "amount" => 19320,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 B 类飞行教员,现有机型教员经历时间10年以上;2、在本公司飞行时间14000小时以上;3、晋升前连续 6 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 3 年无航空安全严重差错。",
            "expr" => "%{drive_work_value} >= 10 and %{fly_time_value} >= 14000"
          }
        },
        "2" => {
          "rate" => 13,
          "amount" => 18200,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 B 类飞行教员,现有机型教员经历时间6年以上;2、在本公司飞行时间10000小时以上;3、晋升前连续 3 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 1 年无航空安全严重差错。",
            "expr" => "%{drive_work_value} >= 6 and %{fly_time_value} >= 10000"
          }
        },
        "3" => {
          "rate" => 12.2,
          "amount" => 17080,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 B 类飞行教员,现有机型教员经历时间3年以上;2、在本公司飞行时间6000小时以上;3、晋升前连续 3 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 1 年无航空安全严重差错。",
            "expr" => "%{drive_work_value} >= 3 and %{fly_time_value} >= 6000"
          }
        },
        "4" => {
          "rate" => 11.4,
          "amount" => 15960,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "现任 B 类飞行教员。",
            "drive_work_value" => 0,
            "fly_time_value" => 0
          }
        }
      }
    }

    Salary.create(category: 'flyer_teacher_B_base', table_type: 'dynamic', form_data: flyer_teacher_B_base)

    flyer_teacher_A_base = {
      "flag_list" => ["rate", "amount", "X"],
      "flag_names" => {
        "rate" => "系数",
        "amount" => "金额",
        "X" => "默认"
      },
      "flags" => {
        "1" => {
          "rate" => 12.2,
          "amount" => 17080,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 A 类飞行教员,现有机型教员经历时间6年以上;2、在本公司飞行时间8000小时以上;3、晋升前连续 6 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 3 年无航空安全严重差错。",
            "expr" => "%{drive_work_value} >= 6 and %{fly_time_value} >= 8000"
          }
        },
        "2" => {
          "rate" => 11.4,
          "amount" => 15960,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 A 类飞行教员,现有机型教员经历时间4年以上;2、在本公司飞行时间6000小时以上;3、晋升前连续 3 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 1 年无航空安全严重差错。",
            "expr" => "%{drive_work_value} >= 4 and %{fly_time_value} >= 6000"
          }
        },
        "3" => {
          "rate" => 10.6,
          "amount" => 14840,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "1、现任 A 类飞行教员,现有机型教员经历时间2年以上;2、在本公司飞行时间5000小时以上;3、晋升前连续 3 年无人为原因飞行事故征候及以上不良安全记录;4、晋升前 1 年无航空安全严重差错。",
            "expr" => "%{drive_work_value} >= 2 and %{fly_time_value} >= 5000"
          }
        },
        "4" => {
          "rate" => 9.8,
          "amount" => 13720,
          "X" => {
            "grade_list" => [1, 2, 3, 4],
            "bg_color" => "white",

            "format_cell" => "现任 A 类飞行教员。",
            "drive_work_value" => 0,
            "fly_time_value" => 0
          }
        }
      }
    }

    Salary.create(category: 'flyer_teacher_A_base', table_type: 'dynamic', form_data: flyer_teacher_A_base)

    service_c_base = {
      "flag_list" => ["amount", "X"],
      "flag_names" => {
        "amount" => "金额",
        "X" => "X"
      },
      "flags" => {
        "1" => {
          "amount" => 1900,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "新进",
            "transfer_years" => 0
          }
        },
        "2" => {
          "amount" => 2300,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} >= 2"
          }
        },
        "3" => {
          "amount" => 2600,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 4,
            "expr" => "%{transfer_years} >= 4"
          }
        },
        "4" => {
          "amount" => 2900,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 7,
            "expr" => "%{transfer_years} >= 7"
          }
        },
        "5" => {
          "amount" => 3200,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 11,
            "expr" => "%{transfer_years} >= 11"
          }
        },
        "6" => {
          "amount" => 3500,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 15,
            "expr" => "%{transfer_years} >= 15"
          }
        },
        "7" => {
          "amount" => 3800,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 20,
            "expr" => "%{transfer_years} >= 20"
          }
        },
        "8" => {
          "amount" => 4100,
          "X" => {
            "grade_list" => [1, 2, 3, 4, 5, 6, 7, 8],
            "bg_color" => "white",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 25,
            "expr" => "%{transfer_years} >= 25"
          }
        }
      }
    }

    Salary.create(category: 'service_c_base', table_type: 'dynamic', form_data: service_c_base)

    flyer_hour = {
      "teacher_A" => 420,             # 教员 A
      "teacher_B" => 400,             # 教员 B
      "leader_A" => 380,             # 责任机长 A
      "leader_B" => 360,             # 责任机长 B
      "leader" => 240,          # 机 长
      "copilot_special" => 240,      # 副驾驶特别档
      "copilot_1" => 190,            # 副驾驶 1
      "copilot_2" => 165,            # 副驾驶 2
      "copilot_3" => 155,            # 副驾驶 3
      "copilot_4" => 135,            # 副驾驶 4
      "copilot_5" => 130,            # 副驾驶 5
      "copilot_6" => 100,            # 副驾驶 6
      "observer" => 150              # 空中观察员
    }

    Salary.create(category: 'flyer_hour', table_type: 'static', form_data: flyer_hour)

    air_security_hour = {
      "security_A" => 145,             # 资深安 A
      "security_B" => 120,             # 资深安 B
      "security_C" => 105,             # 资深安 C
      "security_D" => 85,             # 资深安 D
      "safety_A" => 70,               # 安全员 A
      "safety_B" => 60,               # 安全员 B
      "safety_C" => 55,               # 安全员 C
      "safety_D" => 50,               # 安全员 D
      "noviciate_safety" => 27         # 见习安
    }

    Salary.create(category: 'air_security_hour', table_type: 'static', form_data: air_security_hour)

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

            "format_cell" => "少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{performance} == '待改进' and %{transfer_years} < 10"
          },
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 2"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 3"
          },
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 2"
          },
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 8"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

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

    Salary.create(category: 'information_perf', table_type: 'dynamic', form_data: information_perf)

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

            "format_cell" => "少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{performance} == '待改进' and %{transfer_years} < 10"
          },
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 2"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 3"
          },
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 2"
          },
          "B" => {
            "grade_list" => [5, 6, 8, 10, 13],
            "bg_color" => "yellow",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 8,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 8"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 11],
            "bg_color" => "green",

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

    Salary.create(category: 'airline_business_perf', table_type: 'dynamic', form_data: airline_business_perf)


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

            "format_cell" => "少于 %{transfer_years} 年",
            "transfer_years" => 10,
            "expr" => "%{performance} == '待改进' and %{transfer_years} < 10"
          },
          "E" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '良好' and %{transfer_years} >= 2"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '合格' and %{transfer_years} >= 3"
          },
          "D" => {
            "grade_list" => [2, 5],
            "bg_color" => "yellow",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 2"
          },
          "B" => {
            "grade_list" => [5, 6, 8, 10, 14],
            "bg_color" => "yellow",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 3,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 3"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{performance} == '优秀' and %{transfer_years} >= 5"
          },
          "C" => {
            "grade_list" => [4, 5, 7, 9, 12],
            "bg_color" => "green",

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

    Salary.create(category: 'manage_market_perf', table_type: 'dynamic', form_data: manage_market_perf)


    service_c_1_perf = {
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

            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

    Salary.create(category: 'service_c_1_perf', table_type: 'dynamic', form_data: service_c_1_perf)


    service_c_2_perf = {
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

            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

    Salary.create(category: 'service_c_2_perf', table_type: 'dynamic', form_data: service_c_2_perf)



    service_c_3_perf = {
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

            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

    Salary.create(category: 'service_c_3_perf', table_type: 'dynamic', form_data: service_c_3_perf)



    service_c_driving_perf = {
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

            "format_cell" => " %{transfer_years} 年及以下",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} < 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} >= 5"
          },
          "E" => {
            "grade_list" => [1, 2],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "D" => {
            "grade_list" => [1, 2, 3],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 2,
            "expr" => "%{transfer_years} > 2"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

            "format_cell" => "不少于 %{transfer_years} 年",
            "transfer_years" => 5,
            "expr" => "%{transfer_years} > 5"
          },
          "C" => {
            "grade_list" => [3, 5, 7, 9],
            "bg_color" => "white",

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

    Salary.create(category: 'service_c_driving_perf', table_type: 'dynamic', form_data: service_c_driving_perf)

    allowance = {
      "security_subsidy" => {         #安检津贴
        "lower" => 100,               #integer, 初级
        "middle" => 400,              #integer, 中级
        "higher" => 600               #integer, 高级
      },
      "placement_subsidy" => 500,     #integer, 安置津贴
      "leader_subsidy" => {           #班组长津贴
        "line_A" => 100,              #integer, 一线A类
        "line_B" => 100,              #integer, 一线B类
        "line_C" => 100,              #integer, 一线C类
        "line_D" => 100,              #integer, 一线D类
        "logistics_1" => 100,         #integer, 后勤一类
        "logistics_2" => 100          #integer, 后勤二类
      },
      "terminal_subsidy" => {         #航站管理津贴
        "first" => 100,               #integer, 一类
        "second" => 100               #integer, 二类
      },
      "car_subsidy" => 500,           #车勤补贴
      "ground_subsidy" => {           #地勤补贴
        "first" => 100,               #integer, 一类
        "second" => 100,              #integer, 二类
        "third" => 100,               #integer, 三类
        "fourth" => 100,              #integer, 四类
        "fifth" => 100,               #integer, 五类
        "sixth" => 100                #integer, 六类
      },
      "machine_subsidy" => {          #机务放行补贴
        "first" => 100,               #integer, 一档
        "second" => 100,              #integer, 二档
        "third" => 100,               #integer, 三档
        "fourth" => 100,              #integer, 四档
        "fifth" => 100                #integer, 五档
      },
      "trial_subsidy" => {            #试车津贴
        "first" => 100,               #integer, 一类
        "second" => 100               #integer, 二类
      },
      "honor_subsidy" => {            #飞行安全荣誉津贴
        "copper" => 100,              #integer, 铜质
        "silver" => 100,              #integer, 银质
        "gold" => 100,                #integer, 金质
        "exploit" => 100              #integer, 功勋
      }
    }

    Salary.create(category: 'allowance', table_type: 'static', form_data: allowance)


    land_subsidy = {
      "general" => {                  #普通
        "amount" => 100,              #integer, 标准
        "cities" => []                #integer, 城市
      },
      "highland_1st" => {             #高原1
        "amount" => 120,
        "cities" => ["拉萨", "九黄"]
      },
      "highland_2nd" => {             #高原2
        "amount" => 135,
        "cities" => ["康定", "稻城"]
      },
      "high_cold" => {                #高寒
        "amount" => 60,
        "cities" => ["乌鲁木齐", "哈尔滨"]
      },
      "overseas_1st" => {             #境外1
        "amount" => 80,
        "cities" => ["首尔", "温哥华", "墨尔本", "悉尼", "大阪", "东京", "迪拜", "莫斯科"]
      },
      "overseas_2nd" => {             #境外2
        "amount" => 70,
        "cities" => ["普吉", "香港", "台湾"]
      },
      "overseas_3rd" => {             #境外3
        "amount" => 60,
        "cities" => ["河内", "胡志明", "加德满都"]
      }
    }

    Salary.create(category: 'land_subsidy', table_type: 'static', form_data: land_subsidy)


    airline_subsidy = {
      "inland_areas" => [             #国内驻站地点
        {
          "city" => "北京",
          "abbr" => "京"
        },
        {
          "city" => "石家庄",
          "abbr" => "石"
        },
        {
          "city" => "南宁",
          "abbr" => "邕"
        },
        {
          "city" => "海口",
          "abbr" => "琼"
        },
        {
          "city" => "三亚",
          "abbr" => "三"
        },
        {
          "city" => "昆明",
          "abbr" => "昆"
        }
      ],
      "outland_areas" => [           #国外驻站地点
        {
          "city" => "温哥华",
          "abbr" => "温"
        },
        {
          "city" => "塞班",
          "abbr" => "塞"
        },
        {
          "city" => "莫斯科",
          "abbr" => "谢"
        },
        {
          "city" => "墨尔本",
          "abbr" => "墨"
        },
        {
          "city" => "悉尼",
          "abbr" => "悉"
        }
      ],
      "inland_subsidy" => {          #国内补贴标准
        "airline" => {               #飞行
          "general" => 180,          #普通驻站,单位：元/天
          "metaphase" => 6500,       #中期驻站,单位：元/月
          "long_term" => 8000        #长期驻站,单位：元/月
        },
        "cabin" => {                 #客舱
          "general" => 100,
          "metaphase" => 3500,
          "long_term" => 4000
        },
        "air_security" => {          #空保
          "general" => 100,
          "metaphase" => 3500,
          "long_term" => 4000
        }
      },
      "outland_subsidy" => 50        #外国餐食补助标准,单位：美元/天
    }

    Salary.create(category: 'airline_subsidy', table_type: 'static', form_data: airline_subsidy)

    temp = {
      'city_list' => [
        {"start_month"=>6, "end_month"=>8, "cities"=>["北京", "天津"]},
        {"start_month"=>6, "end_month"=>9, "cities"=>["成都", "昆明", "贵阳"]},
        {"start_month"=>6, "end_month"=>10, "cities"=>["广州", "重庆"]},
        {"start_month"=>3, "end_month"=>11, "cities"=>["三亚", "海口"]}
      ]
    }
    Salary.create(category: 'temp', table_type: 'static', form_data: temp)

    puts "新增#{Salary.count - count}个薪酬设置"
  end

  desc "init cold_subsidy"
  task cold_subsidy: :environment do
    cold_subsidy = {
      'personnel_amount_config' => {
        'A' => {
          'grade_0' => 0,
          'grade_1' => 30,
          'grade_2' => 60,
          'grade_3' => 90,
        },
        'B' => 400,
      },
      'city_config' => [
        {
          'name' => '呼和浩特',
          'M_A_10' => 'grade_0',
          'M_A_11' => 'grade_1',
          'M_A_12' => 'grade_3',
          'M_A_1'  => 'grade_3',
          'M_A_2'  => 'grade_2',
          'M_A_3'  => 'grade_1',
          'M_A_4'  => 'grade_0',
          'M_B_10' => 'true',
          'M_B_11' => 'true',
          'M_B_12' => 'true',
          'M_B_1'  => 'true',
          'M_B_2'  => 'true',
          'M_B_3'  => 'true',
          'M_B_4'  => 'true',
        },
        {
          'name' => '成都',
          'M_A_10' => 'grade_0',
          'M_A_11' => 'grade_1',
          'M_A_12' => 'grade_3',
          'M_A_1'  => 'grade_3',
          'M_A_2'  => 'grade_2',
          'M_A_3'  => 'grade_1',
          'M_A_4'  => 'grade_0',
          'M_B_10' => 'true',
          'M_B_11' => 'true',
          'M_B_12' => 'true',
          'M_B_1'  => 'true',
          'M_B_2'  => 'true',
          'M_B_3'  => 'true',
          'M_B_4'  => 'true',
        },
      ]
    }
    Salary.where(category: 'cold_subsidy').destroy_all
    Salary.create(category: 'cold_subsidy', table_type: 'static', form_data: cold_subsidy)
  end
end
