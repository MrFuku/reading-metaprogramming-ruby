class TryOut
  # このクラスの仕様
  # コンストラクタは、2つまたは3つの引数を受け付ける。引数はそれぞれ、ファーストネーム、ミドルネーム、ラストネームの順で、ミドルネームは省略が可能。
  # full_nameメソッドを持つ。これは、ファーストネーム、ミドルネーム、ラストネームを半角スペース1つで結合した文字列を返す。ただし、ミドルネームが省略されている場合に、ファーストネームとラストネームの間には1つのスペースしか置かない
  # first_name=メソッドを持つ。これは、引数の内容でファーストネームを書き換える。
  # upcase_full_nameメソッドを持つ。これは、full_nameメソッドの結果をすべて大文字で返す。このメソッドは副作用を持たない。
  # upcase_full_name! メソッドを持つ。これは、upcase_full_nameの副作用を持つバージョンで、ファーストネーム、ミドルネーム、ラストネームをすべて大文字に変え、オブジェクトはその状態を記憶する

  def initialize(*args)
    name_check(*args)
    @full_name = args.map(&:to_s)
  end

  def full_name
    @full_name.join(' ')
  end

  def first_name=(first_name)
    @full_name[0] = first_name
  end

  def upcase_full_name
    full_name.upcase
  end
  
  def upcase_full_name!
    @full_name.each(&:upcase!)
    upcase_full_name
  end

  private

  def name_check(*args)
    raise ArgumentError.new("wrong number of arguments (given #{args.length}, expected 2..3)") unless args.length.between?(2, 3)
  end
end
