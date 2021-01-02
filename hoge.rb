class Module
  def const_missing(name)
    p 'name'
  end
end

class Hoge
  def get_hoge_r
    A
  end
end

Hoge.new.get_hoge_r

