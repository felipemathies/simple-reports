module SimpleReports
  class HtmlRenderer < AbstractRenderer
    def print_before_header
      attrs = html_options(@report.html_options)
      "<table#{attrs}>\n"      
    end 
    
    def print_after_body
      "</table>\n"
    end

    def print_header
      columns = @report.columns
      html = ''
      if (columns.size > 0)
        if (columns.all?{|e| e.is_a?(Array)})
          html << "<tr>\n"
          html << columns.inject("") {|memo, h| memo << "<th>#{h[1][:label] || h[0].to_s.titleize}</th>\n"}
          html << "</tr>\n"       
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
        options = html_options(column[1][:html], object)
        value = value(object, column)
        line << "<td#{options}>#{value}</td>\n"
      end
      html = "<tr>\n#{line}</tr>\n" unless line.blank?
      html || ''
    end
    
    def print_line_total(total, aninhamento, objects=nil)
      aninhamento = aninhamento.clone
      aninhamento.shift

      columns = @report.columns
      groups = @report.groups.map{|c| c[0]}.slice(0, aninhamento.size + 1)
      
      line = ''      
      
      columns.each do |column|
        total_report = @report.totals.detect{|t| t[0] == column[0]}        
        options = html_options(total_report[1][:html], objects, total[column[0]]) if total_report 
               
        if (i = groups.index(column[0]))
          if aninhamento[i]
            line << "<td#{options}>#{aninhamento[i]}#{' - ' << total[:label] if total[:label]}</td>\n"
          else
            if aninhamento.size > 0
              line << "<td#{options}>SUBTOTAL</td>\n"
            else
              line << "<td#{options}>TOTAL</td>\n"
            end
          end
        elsif total[column[0]]
          line << "<td#{options}>#{total[column[0]]}</td>\n"
        else
          line << "<td#{options}>-</td>\n"
        end
      end
      html = "<tr id='total'>\n#{line}</tr>\n" unless line.blank? || (aninhamento.size == 0 && !@report.options[:global_total])
      html || ''
    end
    
    def html_options(options, object=nil, value=nil)
      html = ''
      if options && options.size > 0
        html << options.inject('') do |memo, option|
          if option[1].is_a?(Proc) && object 
            propierty_value = value ? option[1].call(object, value) : option[1].call(object) 
          else
            propierty_value = option[1]
          end          
          memo << "#{option[0]}=\"#{propierty_value}\""
        end.sort.join(' ').insert(0, ' ')
      end
      html
    end
  end
end