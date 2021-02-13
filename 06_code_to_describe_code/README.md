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
