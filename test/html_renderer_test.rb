require File.join(File.dirname(__FILE__), 'test_helper.rb')
require File.join(File.dirname(__FILE__), 'test_fixtures.rb')

class SimpleReports::HtmlRendererTest < Test::Unit::TestCase
  def setup
    @data = TestFixtures.data
  end
  
  def test_print_before_header_should_print_table_tags
    report = SimpleReports::Report.new do |r|
      r.html_options = {'border' => 'solid', 'id' => 'report'}
    end
    renderer = SimpleReports::HtmlRenderer.new(report)

    table_header = '<table id="report"border="solid">' + "\n"
    assert_equal table_header, renderer.print_before_header    
  end
  
  def test_after_footer_should_print_end_table_tag
    renderer = SimpleReports::HtmlRenderer.new(nil)
    assert_equal "</table>\n", renderer.print_after_body    
  end
  
  def test_print_header_should_print_column_titles
    dados = @data
    report = SimpleReports::Report.new "sports stuff" do |r|
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price) { |vo| vo.price }
      r.data=(dados)
    end
    
    renderer = SimpleReports::HtmlRenderer.new(report)
    expectd = <<EOF
<tr>
<th>Sport</th>
<th>Equipment type</th>
<th>Description</th>
<th>Price</th>
</tr>
EOF
    assert_equal expectd, renderer.print_header
  end
      
  def test_print_total_should_put_hifens_on_groups
    dados = [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
      VO.new("volleyball", "ball", "nike voleyball", 10),
      VO.new("volleyball", "ball", "adidas voleyball", 20),
    ]
    
    report = SimpleReports::Report.new "sports stuff" do |r|
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price) { |vo| vo.price }
            
      r.group(:sport, :group_by => :sport, :group_name => :sport)
      r.group(:eq_type, :group_by => :eq_type, :group_name => :eq_type)
      
      r.total(:price) do |list|
        list.inject(0) { |memo, v| memo += v.price }
      end
      
      r.total(:eq_type) do |list|
        list.first.eq_type[0,1]
      end
      
      r.data=(dados)
    end

    renderer = SimpleReports::HtmlRenderer.new(report)

    expectd = <<EOF
<tr id='total'>
<td>soccer</td>
<td>SUBTOTAL</td>
<td>-</td>
<td>3</td>
</tr>
EOF
    actual = renderer.print_line_total({:price => 3, :eq_type => 'd'}, [nil, 'soccer'])    

    assert_equal expectd, actual
  end
  
  def test_print_line_should_print_one_line
    data = [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
    ]
    
    report = SimpleReports::Report.new "sports stuff" do |r|
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price, {}, {"align" => "right"})
      r.data=(data)
    end
    renderer = SimpleReports::HtmlRenderer.new(report)
    
    expected = <<EOF
<tr>
<td>soccer</td>
<td>ball</td>
<td>nike ball</td>
<td align="right">1</td>
</tr>
EOF
    assert_equal expected, renderer.print_line(data[0])

    expected = <<EOF
<tr>
<td>soccer</td>
<td>ball</td>
<td>adidas ball</td>
<td align="right">2</td>
</tr>
EOF
    assert_equal expected, renderer.print_line(data[1])
  end
  
  def test_print_should_print_nothing_on_empty_report
    dados = [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
    ]
    report = SimpleReports::Report.new "sports stuff" do |r|
      r.data=(dados)
      r.renderer = SimpleReports::HtmlRenderer.new(r)
    end

    assert_equal "<table>\n</table>\n", report.print
  end
  
  def test_print_should_print_table
    data = [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
    ]
    
    report = SimpleReports::Report.new "sports stuff" do |r|
      r.data=(data)
      r.renderer = SimpleReports::HtmlRenderer.new(r)

      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price, {}, {"align" => "right"})
    end
    
    expected = <<EOF
<table>
<tr>
<th>Sport</th>
<th>Equipment type</th>
<th>Description</th>
<th>Price</th>
</tr>
<tr>
<td>soccer</td>
<td>ball</td>
<td>nike ball</td>
<td align="right">1</td>
</tr>
<tr>
<td>soccer</td>
<td>ball</td>
<td>adidas ball</td>
<td align="right">2</td>
</tr>
</table>
EOF
    assert_equal expected, report.print
  end
  
  def test_print_should_print_table_with_totalizers_with_labels
    dados = [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
    ]
    
    report = SimpleReports::Report.new "sports stuff", :global_total => true do |r|
      r.data=(dados)
      r.renderer = SimpleReports::HtmlRenderer.new(r)
      
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price) { |vo| vo.price }
            
      r.group(:sport, :group_by => :sport, :group_name => :sport)
      
      r.total(:price, {:label => "Price"}) do |list|
        list.inject(0) { |memo, v| memo += v.price }
      end
      
      r.total(:desc) do |list|
        "desc"
      end
    end

    expectd = <<EOF
<table>
<tr>
<th>Sport</th>
<th>Equipment type</th>
<th>Description</th>
<th>Price</th>
</tr>
<tr>
<td>soccer</td>
<td>ball</td>
<td>nike ball</td>
<td>1</td>
</tr>
<tr>
<td>soccer</td>
<td>ball</td>
<td>adidas ball</td>
<td>2</td>
</tr>
<tr id='total'>
<td>soccer - Price</td>
<td>-</td>
<td>desc</td>
<td>3</td>
</tr>
<tr id='total'>
<td>TOTAL</td>
<td>-</td>
<td>desc</td>
<td>3</td>
</tr>
</table>
EOF
    assert_equal expectd, report.print
  end
  
  def test_html_options_should_generate_propor_html_options
    renderer = SimpleReports::HtmlRenderer.new(nil)
    
    opts = nil
    assert_equal '', renderer.html_options(opts)
    opts = {}
    assert_equal '', renderer.html_options(opts)
    opts = {"align" => "right", "size" => "0"}
    assert_equal ' size="0"align="right"', renderer.html_options(opts)
  end
end