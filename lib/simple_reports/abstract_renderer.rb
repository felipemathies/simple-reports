module SimpleReports
  class AbstractRenderer
    attr_reader :report 
    
    def initialize(report)
      @report = report
    end
    
    def print
      data = ''
      data << self.print_before_header
      data << self.print_header
      data << self.print_body
      data << self.print_after_body
      data
    end
    
    def print_before_header
      ''
    end
    
    def print_after_body
      ''
    end
    
    def print_header      
      ''
    end
    
    def print_line(object)
      ''
    end
    
    def print_line_total(total, aninhamento)
      ''
    end
  
    protected
      
    def print_body(data = @report.grouped_data, nesting = [])
      html = ''
      total = data.delete(:total)
      group_name = data.delete(:group_name)
      
      objects = data[:group_data]
        
      if objects # there is no more nested nodes
        html << print_lines(objects) if !@report.options[:group]
      else # still having nested data
        data.values.each do |v|
          nesting.push(group_name)
          html << print_body(v, nesting)
          nesting.pop
        end
      end
      nesting.push(group_name)
      total.each do |t| 
        html << print_line_total(t, nesting, objects) if @report.groups.size > 0 
      end
      nesting.pop
      html
    end
    
    def print_lines(data)
      html = ''
      data.each do |object|
        html << print_line(object)
      end
      html
    end

    def value(object, column)
      call_proc_or_method(object, column[1][:proc] || column[0])
    end
    
    def call_proc_or_method(obj, proc_or_method, proc_param = obj)
      if proc_or_method.is_a?(Proc)
        proc_or_method.call(proc_param)
      else
        obj.send(*proc_or_method)
      end    
    end
  end
end