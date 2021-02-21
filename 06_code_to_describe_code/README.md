## 6.2 Kernel#eval
文字列として渡されたコードを実行する
```
array = [10, 20]
element = 30
eval("array << element") # => [10, 20, 30]
```

### 6.2.1 Rest Client の例

```
POSSIBLE_VERBS = ['get', 'put', 'post', 'delete']

POSSIBLE_VERBS.each do |m|
	eval <<-end_eval
		def #{m}(path, *args, &b)
			r[path].#{m}(*args, &b)
		end
	end_eval
end
```

### 6.2.2 Binding オブジェクト
Binding はスコープをオブジェクトにまとめる

```
class MyClass
	def my_method
		@x = 1
		binding
	end
end

b = MyClass.new.my_method
eval "@x", b # => 1
```

Ruby には、事前に定義された定数 TOPLEVEL_BINDING が用意されており、トップレベルのスコー プの Binding になっている。これを使えば、トップレベルのスコープにプログラムのどこからでも アクセスできる。

```
class AnotherClass
	def my_method
		eval "self", TOPLEVEL_BINDING
	end
end

AnotherClass.new.my_method # => main
```

## 6.2.5 eval の問題点

### コードインジェクション
コードインジェクションをされる可能性があり、外部入力文字列を気軽に実行してはならない。

```
def explore_array(method)
	code = "['a', 'b', 'c'].#{method}"
	puts "Evaluating: #{code}"
	eval code
end

loop { p explore_array(gets.chomp) }
```

```
object_id; Dir.glob("*")
['a', 'b', 'c'].object_id; Dir.glob("*") => [プライベートな情報がズラズラと表示される ]
```

### コードインジェクションから身を守る

### send で書き直す
ただし、この方法ではブロックを渡せない
```
def explore_array(method, *arguments)
	['a', 'b', 'c'].send(method, *arguments)
end
```

### オブジェクトの汚染とセーフレベル
tainted? メソッドでオブジェクトの汚染を判定できる
```
# ユーザー入力を読み込む
user_input = "User input: #{gets()}"
puts user_input.tainted?
```

```
⇐ x=1
⇒ true
```

セーフレベルを設定する(グローバル変数 $SAFE に値を設定する)と、潜在的に危険な操作をある程度は制限できる。
デフォルト 0、最大 3。
セーフレベル 2 では、ファイル操作はほとんど 認められていない。
0 より大きいセーフレベルでは、Ruby は汚染した文字列を評価できない。

```
$SAFE = 1

user_input = "User input: #{gets()}"
eval user_input
```

```
⇐ x=1
⇒ SecurityError: Insecure operation - eval
```

### ERB の例

テンプレートから抜き出した Ruby のコードを受け取り、それを eval に渡すメソッドが ERB のソース
```
class ERB
def result(b=new_toplevel)
	if @safe_level
		proc {
			$SAFE = @safe_level
			eval(@src, b, (@filename || '(erb)'), 0)
		}.call
	else
		eval(@src, b, (@filename || '(erb)'), 0)
	end
end
#...
```

## 6.3 クイズ:アトリビュートのチェック(手順 1)

1. eval を使った add_checked_attribute という名前のカーネルメソッド(p.33)を書いて、ク ラスに超シンプルな妥当性確認済みのアトリビュートを追加できるようにする。
2. add_checked_attribute をリファクタリングして、eval を削除する。

以下、要件を表現したテストケース
```ruby
require 'test/unit'

class Person; end

class TestCheckedAttribute < Test::Unit::TestCase
	def setup
		add_checked_attribute(Person, :age)
		@bob = Person.new
	end

	def test_accepts_valid_values
		@bob.age = 20
		assert_equal 20, @bob.age
	end

	def test_refuses_nil_values
		assert_raises RuntimeError, 'Invalid attribute' do
		@bob.age = nil
		end
	end

	def test_refuses_false_values
		assert_raises RuntimeError, 'Invalid attribute' do
			@bob.age = false
		end
	end
end

# これから実装するメソッド
def add_checked_attribute(klass, attribute)
	# ...
end
```

## 6.3.1 このクイズに答える前に

attr_accessorの例
attr_accessorは以下のような2つのミミックメソッド(p.226)を生成する。

```ruby
def my_attr
	@my_attr
end

def my_attr=(value)
	@my_attr = value
end
```

## 6.3.2 クイズの答え
```ruby
def add_checked_attribute(klass, attribute)
	eval "
		class #{klass}
			def #{attribute}=(value)
				railse 'Invalid attribute' unless value
				@#{attribute} = value
			end

			def #{attribute}()
				@#{attribute}
			end
		end
	"
end
```

評価されると以下のようなコードを生成する
```ruby
class String
	def my_attr=(value)
		raise 'Invalid attribute' unless value
		@my_attr = value
	end

	def my_attr()
		@my_attr
	end
end
```

## 6.4 クイズ:アトリビュートのチェック(手順 2)

コードから eval を削除する場面。

### 6.4.1 クイズの答え

evalを使わずにクラスのスコープに入る
```ruby
def add_checked_attribute(klass, attribute)
	klass.class_eval do
		# ...
	end
end
```

add_checked_attribute実行時に動的にメソッドを定義するため、define_methodを使う。
```ruby
def add_checked_attribute(klass, attribute)
	klass.class_eval do
		define_method "#{attribute}=" do |value|
			# ...
		end

		define_method attribute do
			# ...
		end
	end
end
```

Object#instance_variable_get と Object#instance_variable_setを使ってインスタンス変数の読み書きを行う。
```ruby
def add_checked_attribute(klass, attribute)
	klass.class_eval do
		define_method "#{attribute}=" do |value|
			raise 'Invalid attribute' unless value
			instance_variable_set("@#{attribute}", value)
		end

		define_method attribute do
			instance_variable_get "@#{attribute}"
		end
	end
end
```

## 6.5 クイズ:アトリビュートのチェック(手順 3)
本日のプロジェクトに柔軟性を散りばめる場面（ブロックでアトリビュートの妥当性を確認 する）。

要件を満たすよう、テストケースを修正
```ruby
require 'test/unit'

class Person; end

class TestCheckedAttribute < Test::Unit::TestCase
	def setup
		add_checked_attribute(Person, :age) {|v| v >= 18 }
		@bob = Person.new
	end

	def test_accepts_valid_values
		@bob.age = 20
		assert_equal 20, @bob.age
	end

	def test_refuses_invalid_values
		assert_raises RuntimeError, 'Invalid attribute' do
			@bob.age = 17
		end
	end

	def add_checked_attribute(klass, attribute, &validation)
		# ... ( このコードはまだテストをパスしない。要修正。)
	end
end
```

### 6.5.1 クイズの答え
add_checked_attribute を数行変更すれば、テストをパスさせて、クイズに答えることができる。

```ruby
def add_checked_attribute(klass, attribute, &validation)
	klass.class_eval do
		define_method "#{attribute}=" do |value|
			raise 'Invalid attribute' unless validation.call(value)
			instance_variable_set("@#{attribute}", value)
		end

		define_method attribute do
			instance_variable_get "@#{attribute}"
		end
	end
end
```

## 6.6 クイズ:アトリビュートのチェック(手順 4)
トリックの鞄からクラスマクロを取り出す場面。

カーネルメソッドをすべてのクラスで使えるクラスマクロ(p.122)に 変更する。
add_checked_attribute メソッドを attr_checked メソッドに変更するということ。

```ruby
require 'test/unit'

class Person
  attr_checked :age do |v|
    v >= 18 
  end
end

class TestCheckedAttribute < Test::Unit::TestCase
  def setup
    @bob = Person.new
  end

  # ...
end
```

### 6.6.1 クイズの答え
「5.1 クラス定義のわかりやすい説明」で議論したことを思い出してほしい。attr_checked をあらゆるクラス定義で使うには、Class または Module のインスタンスメソッドにすればいいのだった。

```ruby
class Class
  def attr_checked(attribute, &validation)
    define_method "#{attribute}=" do |value|
      raise 'Invalid attribute' unless validation.call(value)
      instance_variable_set("@#{attribute}", value)
    end

    define_method attribute do
      instance_variable_get "@#{attribute}"
    end
  end
end
```
このコードでは、class_eval を呼び出す必要すらない。メソッドが実行されるときには、クラスが self の役割を担っているからだ。

## 6.7 フックメソッド
コーディングする前にビルの徹底講義を聴く場面。

Class#inheritedはクラスの継承をフックして呼び出されるメソッド
Class#inherited のようなメソッドは、特定のイベントにフッ クを掛けることから、フックメソッドと呼ばれる。
```ruby
class String
	def self.inherited(subclass)
		puts "#{self} は #{subclass} に継承された "
	end
end

class MyString < String; end
```

### 6.7.1 その他のフック
Ruby にはさまざまなフックがあり、オブジェクトモデルの重要なイベントのほとんどが 網羅されている。Class#inherited でクラスのライフサイクルにプラグインできるように、 Module#included や(Ruby 2.0 から導入された)Module#prepended をオーバーライドすれば、モジュールのライフサイクルにプラグインできる。

```ruby
module M1
	def self.included(othermod)
		puts "M1 は #{othermod} にインクルードされた "
	end
end

module M2
	def self.prepended(othermod)
		puts "M2 は #{othermod} にプリペンドされた "
	end
end

class C
	include M1
	prepend M2
end

⇒ M1 は C にインクルードされた
  M2 は C にプリペンドされた
```

Module#extended をオーバーライドすれば、モジュールがオブジェクトを拡張したときにコード を実行できる。Module#method_added、method_removed、method_undefined をオーバーライドすれば、 メソッドに関連したイベントを実行できる。

```ruby
module M
	def self.method_added(method)
		puts " 新しいメソッド:M##{method}"
	end

	def my_method; end
end
⇒ 新しいメソッド:M#my_method
```
これらのフックは、オブジェクトのクラスに住むインスタンスメソッドにしか使えない。
特異メソッドのイ ベントをキャッチするには、Kernel#singleton_method_added、singleton_method_removed、singleton_ method_undefined を使う。

### 6.7.2 VCR の例
VCR は、HTTP呼び出しを記録および再生するgemである。VCR の Requestクラスは、 Normalizers::Body モジュールをインクルードしている。

```ruby
module VCR
  class Request #...
  	include Normalizers::Body
	#...
```
Request が Normalizers::Body をインクルードすると、クラスメソッドが手に入る。
通常はクラスメソッドではなく、インスタ ンスメソッドが手に入る。Normalizers::Body などのミックスインは、どのようにインクルーダーの クラスメソッドを定義しているのだろうか?

```ruby
module VCR
	module Normalizers
		module Body
			def self.included(klass)
				klass.extend ClassMethods
			end
			
			module ClassMethods
				def body_from(hash_or_string)
					# ...
```

Body には ClassMethods という名前の内部クラ スがあり、そこに body_from などの通常のインスタンスメソッドが定義されている。
それから、 Body には included というフックメソッド(p.164)がある。Request が Body をインクルードすると、 一連のイベントがトリガーされる。

- Ruby が、Body の included フックを呼び出す。
- フックが Request に戻り、ClassMethods モジュールをエクステンドする。
- extend メソッドが、ClassMethods のメソッドを Request の特異クラスにインクルードする (「5.5 クイズ:モジュールの不具合」で説明したトリックだ)。

こうしたクラスメソッドとフックを組み合わせたイディオムは、非常によく使われている。以前 の Rails のソースコードのなかでも広範囲に使用されていた。「10 章 Active Support の Concernモジュール」で説明するように、Rails はすでに別の仕組みに切り替えている。だが、VCR を含めたさまざまな gem において、今でもこのイディオムが使われている。

## 6.8 クイズ:アトリビュートのチェック(手順 5)
最終的にビルから敬意とメタプログラミングの達人の称号をもらう場面。

```ruby
class Class
	def attr_checked(attribute, &validation)
		define_method "#{attribute}=" do |value|
			raise 'Invalid attribute' unless validation.call(value) 
			instance_variable_set("@#{attribute}", value)
		end
	
		define_method attribute do
			instance_variable_get "@#{attribute}"
		end
	end
end
```

attr_checkedをCheckedAttributesモジュールをインクルードしたクラスだけがアクセスできるようにしたい。

要件をもとにテストコードの修正
```ruby
require 'test/unit'

class Person
	include CheckedAttributes
	
	attr_checked :age do |v|
		v >= 18
	end
end

class TestCheckedAttributes < Test::Unit::TestCase
	def setup
		@bob = Person.new
# ...
```

### 6.8.1 クイズの答え
「6.7.2 VCR の例」で学んだトリックをコピーすればいい。CheckedAttributes は、インクルー ダーのクラスメソッドとして attr_checked を定義する。

```ruby
module CheckedAttributes
	def self.included(base)
		base.extended ClassMethods
	end

	module ClassMethods
		def attr_checked(attribute, &validation)
			define_method "#{attribute}=" do |value|
				raise 'Invalid attribute' unless validation.call(value) 
				instance_variable_set("@#{attribute}", value)
			end
		
			define_method attribute do
				instance_variable_get "@#{attribute}"
			end
		end
	end
end
```

## 6.9 まとめ

今日は、独自のクラスマクロ(p.122)を書いて、メタプログラミングの難しい問題を解決した。 そのなかで、強力な eval メソッドとその問題と回避策について学んだ。それから、Ruby のフック メソッド(p.164)に触れて、うまく活用することができた。