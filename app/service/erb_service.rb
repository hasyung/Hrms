class ErbService
  def initialize(path, controller_binding)
    @path = path
    @controller_binding = controller_binding
  end

  def to_html
    template = File.open(@path).read
    erb = ERB.new(template)
    erb.result(@controller_binding)
  end
end
