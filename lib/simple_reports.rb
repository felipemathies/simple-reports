module SimpleReports
  class Report
    attr_accessor :name, :data, :html_options, :options, :renderer
    attr_reader :columns, :groups, :grouped_data, :filters, :totals
  
    def self.html_report(name = "Report", options = {}, html_options = {}, &block)
      report = SimpleReports::Report.new(name, options, html_options, &block)
      renderer = SimpleReports::HtmlRenderer.new(report)
      renderer.print
    end  
  
    def self.html_horizontal_report(name = "Report", options = {}, html_options = {}, &block)
      report = SimpleReports::Report.new(name, options, html_options, &block)
      renderer = SimpleReports::HtmlHorizontalRenderer.new(report)
      renderer.print
    end
  
    def self.xml_report(name = "Report", options = {}, html_options = {}, &block)
      report = SimpleReports::Report.new(name, options, html_options, &block)
      renderer = SimpleReports::XmlRenderer.new(report)
      renderer.print
    end  
    
    #:group => true/false - wheater shows or not lines not referring totals
    #:global_total => true/false - wheater shows or not global total line
    REPORT_OPTIONS = [:group, :global_total]
    def initialize(name = "Report", options = {}, html_options = {}, &block)
      raise "options not allowed: #{(options.keys - REPORT_OPTIONS).join(', ')}" unless options.keys.all?{|o| REPORT_OPTIONS.include?(o)}
      @name, @html_options, @options = name, html_options, options
    
      @columns = []
      @groups = []
      @totals = []
      @data = []
      @filters = []
      @grouped_data = nil
    
      yield self if block_given?
      
      group_data
    end

    #:label => column title
    COLUMN_OPTIONS = [:label]
    #examples:
    #
    # r.column :quantidade {|o| o.quantidade }
    #
    # r.column :quantidade, {}, {"align"=>"right"} do |o| 
    #   o.quantidade
    # end 
    #
    # r.column :quantidade, :label => "Quantidade de material" do |obj|
    #   obj.quantidade.to_s << " " << obj.unidade
    # end
    def column(column, options = {}, html_options = {}, &block)
      raise "options not allowed: #{(options.keys - COLUMN_OPTIONS).join(', ')}" unless options.keys.all?{|o| COLUMN_OPTIONS.include?(o)}
      @columns << [column, options.merge(:proc => block).merge(:html => html_options)]
    end

    #:label => filter title
    FILTER_OPTIONS = [:label]
    #examples:
    #
    # r.filter :quantidade {|o| o.quantidade }
    #
    # r.filter :quantidade, :label => "Quantidade de material"
    def filter(filter, options = {})
      raise "options not allowed: #{(options.keys - FILTER_OPTIONS).join(', ')}" unless options.keys.all?{|o| FILTER_OPTIONS.include?(o)}
      @filters << [filter, options]
    end

    #:group_by => method or proc which return value is used for grouping
    #
    #:group_name => method or proc which return value is used for labeling the group
    GROUP_OPTIONS = [:group_by, :group_name]
    #examples:
    #
    # r.group :material
    # 
    # r.group :material, :group_by => :material_id, :group_name => :name
    # 
    # r.group :material, :group_by => Proc.new{|e| e.material_id}, :group_name => Proc.new{|list| list.first.name}
    def group(group, options = {})
      raise "options not allowed: #{(options.keys - GROUP_OPTIONS).join(', ')}" unless options.keys.all?{|o| GROUP_OPTIONS.include?(o)}
      @groups << [group, options]
    end
  
    #:if => condition wheater the total is or isn't going to be displayed
    TOTAL_OPTIONS = [:if, :label]
    #example:
    #
    # r.total :quantity do |list|
    #   list.inject(0) { |memo, e| memo += e.quantity }
    # end
    # 
    # r.total :quantity, :if => Proc.new {|group_objects| group_objects.all?{|o| o.unit=='kg'} } do |list|
    #   list.inject(0) { |memo, e| memo += e.quantidade }
    # end
    def total(column, options={}, html_options={}, &block)
      raise "block needed" unless block_given? 
      raise "options not allowed: #{(options.keys - TOTAL_OPTIONS).join(', ')}" unless options.keys.all?{|o| TOTAL_OPTIONS.include?(o)}
      @totals << [column, options.merge(:proc => block).merge(:html => html_options)]
    end
  
    def average(column, method, options = {}, html_options={})
      total(column, options, html_options) do |list|
        list = list.compact
        list.inject(0){|memo, e| memo += e.send(method)} / list.size if !list.empty?
      end
    end
  
    def sum(column, method, options = {}, html_options={})
      total(column, options, html_options) do |list|
        list.inject(0){|memo, e| memo += e.send(method)}
      end
    end
    
    def print
      raise "No renderer defined!" unless renderer
      renderer.print
    end
  
    private
    
    def group_data        
      @grouped_data = do_group(@data)
    end
    
    def do_group(data, remaining_groups = @groups.clone)
      if remaining_groups.empty? #end of the tree
        grouped_data = {:group_data => data, :total => totalize(data)}
      else
        group = remaining_groups.delete_at(0)
        total = totalize(data)
        grouped_data = data.group_by{ |t| value(group[1][:group_by] || group[0], t)}
      
        grouped_data.each do |group_name, group_objects|
          name = value(group[1][:group_name] || group[0], grouped_data[group_name].first, grouped_data[group_name])
          grouped_data[group_name] = do_group( group_objects, remaining_groups.clone).merge(:group_name => name)
        end
        grouped_data.merge!(:total => total)
      end
      grouped_data
    end
    
    def totalize(data)
      array_total = []
      total = {}
      @totals.each do |t|
        if total.has_key?(t[0])
          array_total << total
          total = {} 
        end
        total.store(t[0], t[1][:proc].call(data)) if t[1][:if].nil? || t[1][:if].call(data)
        total.store(:label, t[1][:label]) if t[1][:label]
      end
      array_total << total
    end
      
    def value(proc_or_method, obj, proc_param = obj)
      if proc_or_method.is_a?(Proc)
        proc_or_method.call(proc_param)
      else
        obj.send(*proc_or_method)
      end    
    end
  end
end