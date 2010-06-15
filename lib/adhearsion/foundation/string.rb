class String

  def unindent
    gsub(/^\s*/,'')
  end

  def unindent!
    gsub!(/^\s*/,'')
  end

  def self.random_char
    case random_digit = rand(62)
      when  0...10 then random_digit.to_s
      when 10...36 then (random_digit + 55).chr
      when 36...62 then (random_digit + 61).chr
    end
  end

  def self.random(length_of_string=8)
    Array.new(length_of_string) { random_char }.join
  end

  def nameify() downcase.gsub(/[^\w]/, '') end
  def nameify!() replace nameify end

end