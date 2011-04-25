module SimpleReports
  class XmlRenderer < AbstractRenderer
    def print_before_header
      "<report>\n"      
    end 
    
    def print_after_body
      "</report>\n"
    end

    def print_header
      columns = @report.columns
      filters = @report.filters
      html = ''
      if (columns.size > 0)
        if (columns.all?{|e| e.is_a?(Array)})

          html << "<header>\n"
          columns.each do |column|
            options = html_options(column[1][:html])
            html << "<column source=\"#{column[0]}\"#{options}>#{column[1][:label] || column[0].to_s.titleize}</column>\n"
          end
          
          filters.each do |filter|
            html << "<filter source=\"#{filter[0]}\">#{filter[1][:label] || filter[0].to_s.titleize}</filter>\n"
          end
            
          html << "</header>\n"       
        else
          raise "Unexpected header description #{columns.inspect}"
        end
      end
      html
    end
    
    def print_line(object)
      columns = @report.columns
      line = ''
      columns.each do |column|
        value = value(object, column)
        line << "<#{column[0]}>#{value}</#{column[0]}>\n"
      end
      html = "<line>\n#{line}</line>\n" unless line.blank?
      html || ''
    end
    
    def print_line_total(total, aninhamento)
      aninhamento = aninhamento.clone
      aninhamento.shift

      columns = @report.columns
      groups = @report.groups.map{|c| c[0]}.slice(0, aninhamento.size)
      
      line = ''
      columns.each do |column|
        if (i = groups.index(column[0]))
          line << "<#{column[0]}>#{aninhamento[i]}</#{column[0]}>\n"
        elsif total[column[0]]
          line << "<#{column[0]}>#{total[column[0]]}</#{column[0]}>\n"
        else
          line << "<#{column[0]}>-</#{column[0]}>\n"
        end
      end
      html = "<line id='total'>\n#{line}</line>\n" unless line.blank?
      html || ''
    end
    
    def html_options(options)
      html = options.map{|option| "#{option[0]}=\"#{option[1]}\""}.sort.join(' ').insert(0, ' ') if options && options.size > 0
      html || ''
    end
  end
end