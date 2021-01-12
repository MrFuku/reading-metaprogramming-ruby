- クラスは高性能なモジュール
  - クラス定義に間することはモジュール定義にも置き換えることができる


## class_eval
レシーバーとなるクラスのコンテキストで処理を実行できる。
引数として渡すブロック内はフラットスコープ。
https://docs.ruby-lang.org/ja/latest/method/Module/i/class_eval.html

```
class C
end
a = 1
C.class_eval %Q{
  def m                   # メソッドを動的に定義できる。
    return :m, #{a}
  end
}

p C.new.m        #=> [:m, 1]
```
