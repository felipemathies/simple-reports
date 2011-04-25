require File.join(File.dirname(__FILE__), 'test_helper.rb')
require File.join(File.dirname(__FILE__), 'test_fixtures.rb')

class SimpleReports::XmlRendererTest < Test::Unit::TestCase
  def setup
    @data = TestFixtures.data
  end
  
  def test_print_before_header_should_print_report_tags
    report = SimpleReports::Report.new
    renderer = SimpleReports::XmlRenderer.new(report)

    table_header = "<report>\n"
    assert_equal table_header, renderer.print_before_header    
  end
  
  def test_after_footer_should_print_end_table_tag
    report = SimpleReports::Report.new
    renderer = SimpleReports::XmlRenderer.new(report)
    assert_equal "</report>\n", renderer.print_after_body    
  end
  
  def test_print_header_should_print_column_titles
    dados = @data
    report = SimpleReports::Report.new "sports stuff" do |r|
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price, {}, {"align" => "right"})

      r.data=(dados)
    end
    
    renderer = SimpleReports::XmlRenderer.new(report)
    expectd = <<EOF
<header>
<column source="sport">Sport</column>
<column source="eq_type">Equipment type</column>
<column source="desc">Description</column>
<column source="price" align="right">Price</column>
</header>
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

    renderer = SimpleReports::XmlRenderer.new(report)

    expectd = <<EOF
<line id='total'>
<sport>soccer</sport>
<eq_type>d</eq_type>
<desc>-</desc>
<price>3</price>
</line>
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
    renderer = SimpleReports::XmlRenderer.new(report)
    
    expected = <<EOF
<line>
<sport>soccer</sport>
<eq_type>ball</eq_type>
<desc>nike ball</desc>
<price>1</price>
</line>
EOF
    assert_equal expected, renderer.print_line(data[0])

    expected = <<EOF
<line>
<sport>soccer</sport>
<eq_type>ball</eq_type>
<desc>adidas ball</desc>
<price>2</price>
</line>
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
      r.renderer = SimpleReports::XmlRenderer.new(r)
    end

    assert_equal "<report>\n</report>\n", report.print
  end
  def test_html_options_should_generate_propor_html_options
    renderer = SimpleReports::XmlRenderer.new(nil)
    
    opts = nil
    assert_equal '', renderer.html_options(opts)
    opts = {}
    assert_equal '', renderer.html_options(opts)
    opts = {"align" => "right", "size" => "0"}
    assert_equal ' align="right" size="0"', renderer.html_options(opts)
  end
end