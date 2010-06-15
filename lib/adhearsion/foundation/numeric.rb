class Numeric

  def digit()
    ahn_log.deprecation 'Please do not use Fixnum#digit() and Fixnum#digits() in the future! These will be deprecated soon'
    self
  end

  def digits()
    ahn_log.deprecation 'Please do not use Fixnum#digit() and Fixnum#digits() in the future! These will be deprecated soon'
    self
  end

end