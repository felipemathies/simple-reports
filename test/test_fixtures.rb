class TestFixtures  
  def self.data
    [
      VO.new("soccer", "ball", "nike ball", 1),
      VO.new("soccer", "ball", "adidas ball", 2),
      VO.new("soccer", "shirt", "nike shirt", 3),
      VO.new("soccer", "shirt", "reebok shirt", 4),
      VO.new("soccer", "tennis", "nike tennis", 5),
      VO.new("soccer", "tennis", "puma tennis", 5),
      VO.new("soccer", "tennis", "newballance tennis", 10),
      VO.new("soccer", "tennis", "toppper tennis", 10),
      VO.new("volleyball", "ball", "nike voleyball", 10),
      VO.new("volleyball", "ball", "adidas voleyball", 20),
      VO.new("volleyball", "shirt", "nike voley shirt", 30),
      VO.new("volleyball", "shirt", "reebok voley shirt", 40),
    ]
  end
end

class VO
  attr_reader :sport, :eq_type, :price, :desc
  def initialize(sport, eq_type, desc, price)
    @sport, @eq_type, @desc, @price = sport, eq_type, desc, price
  end
    
  def self.code(sport)
    case sport
    when "soccer"
      '01'
    when "volleyball"
      '02'
    end
  end
  
  def inspect
    "#{@sport}-#{@eq_type}-#{@desc}-#{@price}"
  end
end
  