namespace :init do 
  desc "init positinos"
  task :positions => :environment do 
    puts "开始设置岗位"
    puts Time.now
    file_path = "#{Rails.root}/public"
    dep_path = '四川航空'

    InitPosition.init(file_path, dep_path, '保卫部')
    # InitPosition.init(file_path, dep_path, '北京运行基地')
    InitPosition.init(file_path, dep_path, '标准管理部')
    InitPosition.init(file_path, dep_path, '采购管理部')
    InitPosition.init(file_path, dep_path, '党委办公室')
    InitPosition.init(file_path, dep_path, '地面服务部')
    InitPosition.init(file_path, dep_path, '法务审计部')
    InitPosition.init(file_path, dep_path, '飞行部')
    InitPosition.init(file_path, dep_path, '飞行技术管理部')
    #(工程技术分公司/成都维修分部)下属科室无法识别
    InitPosition.init(file_path, dep_path, '工程技术分公司')
    InitPosition.init(file_path, dep_path, '工会办公室')
    # InitPosition.init(file_path, dep_path, '哈尔滨运行基地')
    # InitPosition.init(file_path, dep_path, '杭州运行基地')
    # InitPosition.init(file_path, dep_path, '航空安全监察部')
    InitPosition.init(file_path, dep_path, '航空医疗卫生中心')
    InitPosition.init(file_path, dep_path, '后勤保障部')
    InitPosition.init(file_path, dep_path, '机务工程部')
    # InitPosition.init(file_path, dep_path, '纪检（监察）办公室')
    InitPosition.init(file_path, dep_path, '计划财务部')
    InitPosition.init(file_path, dep_path, '客舱服务部')
    InitPosition.init(file_path, dep_path, '空保大队')
    InitPosition.init(file_path, dep_path, '女职工委员会')
    InitPosition.init(file_path, dep_path, '品牌质量管理部')
    InitPosition.init(file_path, dep_path, '企业管理部')
    InitPosition.init(file_path, dep_path, '企业文化部')
    InitPosition.init(file_path, dep_path, '人力资源部')
    # InitPosition.init(file_path, dep_path, '三亚运行基地')
    InitPosition.init(file_path, dep_path, '商务委员会')
    InitPosition.init(file_path, dep_path, '团委（青年工作部）')
    InitPosition.init(file_path, dep_path, '物流部')
    # InitPosition.init(file_path, dep_path, '西安运行基地')
    InitPosition.init(file_path, dep_path, '信息服务部')
    InitPosition.init(file_path, dep_path, '云南分公司')
    # InitPosition.init(file_path, dep_path, '运行控制中心')
    InitPosition.init(file_path, dep_path, '重庆分公司')
    InitPosition.init(file_path, dep_path, '专家委员会')
    InitPosition.init(file_path, dep_path, '总经理工作部')
    # InitPosition.init(file_path, dep_path, '总经理值班室（国动办、应急办）')
    # InitPosition.init(file_path, dep_path, '商旅公司')
    # InitPosition.init(file_path, dep_path, '文化传媒广告公司')
    # InitPosition.init(file_path, dep_path, '校修中心')

    puts Time.now
    puts '岗位设置完成'
  end
end