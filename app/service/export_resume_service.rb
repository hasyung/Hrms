require 'htmltoword'

class ExportResumeService
  attr_reader :path, :filename

  def initialize(id)
    @id = id
    @name_path_mapper = []
    @employee_klass = Employee.includes(
      [
        :gender, :category, :channel, :marital_status, :education_background,
        :degree, :english_level, :contact, :job_title_degree,
        :employment_status, :labor_relation,
        :employee_positions =>[:position => [:department]]
      ]
    )
    @path = ""
    @filename = ""
  end

  def execute
    if @id.kind_of?(Array)
      batch_write
    else
      single_write
    end
    self
  end

  def batch_write
    @id.each {|id| pdf_write(id) }
    filename = "#{CGI::escape("#{Time.now.to_i}人员履历.zip")}"
    path = "#{Rails.root}/public/export/tmp/#{filename}"
    set_export_name_and_path(filename, path)
    zip_file
  end

  def single_write
    pdf_write(@id)
    set_export_name_and_path(CGI::escape(@name_path_mapper.first["filename"]), @name_path_mapper.first["path"])
  end

  def pdf_write(id)
    @employee = @employee_klass.find(id)
    @languages = @employee.languages
    @contact = @employee.contact
    @education_experiences = @employee.education_experiences

    work_experiences = @employee.work_experiences
    @before_work_experiences = work_experiences.where(category: 'before')
    @after_work_experiences = work_experiences.where(category: 'after')

    family_members = @employee.family_members
    @mate = family_members.where(relation: 'lover').first
    @children = family_members.where(relation: 'children')
    @other_relations = family_members.where(relation: 'other')

    html = ErbService.new("#{Rails.root}/app/views/shared/resume.html.erb", binding).to_html
    filename = "#{Time.now.to_i}#{@employee.name}.doc"
    path = "#{Rails.root}/public/export/tmp/#{filename}"

    FileUtils.mkdir_p("#{Rails.root}/public/export/tmp/") unless File.directory?("#{Rails.root}/public/export/tmp/")

    @name_path_mapper << {"filename" => filename, "path" => path}
    File.open(path, "w"){|f| f.write(html)}
    # Htmltoword::Document.create_and_save(html, path)
  end

  def zip_file
    ::Zip::File.open(@path, Zip::File::CREATE) do |zipfile|
      @name_path_mapper.each do |mapper|
        zipfile.add(mapper["filename"].encode("GBK", :invalid => :replace, :undef => :replace, :replace => "?"), mapper["path"])
      end
    end
  end

  def set_export_name_and_path(name, path)
    @filename, @path = name, path
  end
end
