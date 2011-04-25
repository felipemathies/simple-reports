require File.join(File.dirname(__FILE__), 'test_helper.rb')
require File.join(File.dirname(__FILE__), 'test_fixtures.rb')
require 'mocha'

class AbstractRendererTest < Test::Unit::TestCase
  def setup
    @data = TestFixtures.data
  end
  
  def test_print_should_call_callback_methods
    renderer = SimpleReports::AbstractRenderer.new(nil)
    
    renderer.expects(:print_before_header).returns('1').once
    renderer.expects(:print_header).returns('2').once
    renderer.expects(:print_body).returns('3').once
    renderer.expects(:print_after_body).returns('4').once
    
    assert_equal '1234', renderer.print
  end
  
  def test_print_body_should_delegate_printing_to_print_lines_and_print_line_total  
    soccer_ball_nike = VO.new("soccer", "ball", "nike ball", 1)
    soccer_ball_adidas_ball = VO.new("soccer", "ball", "adidas ball", 2)
    soccer_shirt_blue_shirt = VO.new("soccer", "shirt", "blue shirt", 5)
    soccer_shirt_red_shirt = VO.new("soccer", "shirt", "red shirt", 5)
    volley_ball_nike_ball = VO.new("volley", "ball", "nike ball", 3)
    volley_ball_adidas_ball = VO.new("volley", "ball", "adidas ball", 4)
    
    data = [
      soccer_ball_nike,
      soccer_ball_adidas_ball,
      soccer_shirt_blue_shirt,
      soccer_shirt_red_shirt,
      volley_ball_nike_ball,
      volley_ball_adidas_ball
    ]

    report = SimpleReports::Report.new "sports stuff" do |r|
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price, {}, {"align" => "right"})
        
      r.group(:sport)
      r.group(:eq_type)
        
      r.total(:price) do |objects|
        objects.inject(0){|memo, o| memo += o.price}
      end
      
      r.total(:price) do |objects|
        objects.inject(0){|memo, o| memo += o.price}
      end
      
      r.data=(data)
    end

    renderer = SimpleReports::AbstractRenderer.new(report)
    
    #objects-soccer-ball
    renderer.expects(:print_lines).with([data[0], data[1]]).returns('')
    #subtotal-soccer-ball
    renderer.expects(:print_line_total).with({:price => 3}, [nil, 'soccer', 'ball'], [soccer_ball_nike, soccer_ball_adidas_ball]).returns('').times(2)
    #objects-soccer-shirt
    renderer.expects(:print_lines).with([data[2], data[3]]).returns('')
    #subtotal-soccer-shirt
    renderer.expects(:print_line_total).with({:price => 10}, [nil, 'soccer', 'shirt'], [soccer_shirt_blue_shirt, soccer_shirt_red_shirt]).returns('').times(2)
    #subtotal-soccer
    renderer.expects(:print_line_total).with({:price => 13}, [nil, 'soccer'], nil).returns('').times(2)

    #same thing for volley
    renderer.expects(:print_lines).with([data[4], data[5]]).returns('')
    renderer.expects(:print_line_total).with({:price => 7}, [nil, 'volley', 'ball'], [volley_ball_nike_ball, volley_ball_adidas_ball]).returns('').times(2)
    renderer.expects(:print_line_total).with({:price => 7}, [nil, 'volley'], nil).returns('').times(2)

    #total
    renderer.expects(:print_line_total).with({:price => 20}, [nil], nil).returns('').times(2)
    
    renderer.print
  end
  
  def test_print_body_should_not_print_value_lines_if_group_is_true
    data = [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
    ]    
    report = SimpleReports::Report.new "sports stuff", {:group => true} do |r|
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price, {}, {"align" => "right"})
      r.data=(data)
    end

    renderer = SimpleReports::AbstractRenderer.new(report)
    renderer.expects(:print_line).never

    renderer.send(:print_body)
  end
  
  def test_print_lines_should_receive_array_and_delegate_to_print_line
    data = %w[book notebook stickypad]

    renderer = SimpleReports::AbstractRenderer.new(nil)
    renderer.expects(:print_line).with('book').returns('book-')
    renderer.expects(:print_line).with('notebook').returns('notebook-')
    renderer.expects(:print_line).with('stickypad').returns('stickypad')

    lines = renderer.send(:print_lines, data)
    assert_equal 'book-notebook-stickypad', lines
  end
  
  def test_value_should_return_value_for_column
    data = [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
    ]    
    report = SimpleReports::Report.new "sports stuff", {:group => true} do |r|
      r.column(:sport){|vo| vo.sport}
      r.column(:eq_type, :label => "Equipment type") {|vo| vo.eq_type }
      r.column(:desc, :label => "Description") {|vo| vo.desc}
      r.column(:price, {}, {"align" => "right"})
      r.data=(data)
    end
    renderer = SimpleReports::AbstractRenderer.new(nil)
    
    assert_equal "soccer", renderer.send(:value, data[0], report.columns[0])
    assert_equal "ball", renderer.send(:value, data[0], report.columns[1])
    assert_equal 1, renderer.send(:value, data[0], report.columns[3])
    
    assert_equal "soccer", renderer.send(:value, data[1], report.columns[0])
    assert_equal "ball", renderer.send(:value, data[1], report.columns[1])
    assert_equal 2, renderer.send(:value, data[1], report.columns[3])
  end
  
  def test_call_proc_or_method_should_call_method_or_proc_and_return_value
    object = mock
    params = mock
    
    params.expects(:proc).returns('proc with params').once
    object.expects(:proc).returns('proc').once
    object.expects(:method).returns('method').once
    proc = Proc.new {|param| param.proc}


    renderer = SimpleReports::AbstractRenderer.new(nil)
    assert_equal 'method', renderer.send(:call_proc_or_method, object, :method)
    assert_equal 'proc with params', renderer.send(:call_proc_or_method, object, proc, params)
    assert_equal 'proc', renderer.send(:call_proc_or_method, object, proc)
  end
end