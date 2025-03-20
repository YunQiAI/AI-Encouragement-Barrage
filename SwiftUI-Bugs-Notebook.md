# SwiftUI 错题本

本文档记录了在开发过程中遇到的常见错误和解决方案，作为参考以避免在未来的开发中重复犯同样的错误。

## 1. 结构体中使用 weak self

**错误信息**：
```
'weak' may only be applied to class and class-bound protocol types, not 'StructName'
```

**问题描述**：  
在SwiftUI的View结构体中使用闭包时，错误地使用了`[weak self]`捕获列表。由于结构体是值类型，不存在引用循环问题，因此不能使用`weak self`。

**错误代码示例**：
```swift
struct MyView: View {
    var body: some View {
        Button("Tap") {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SomeNotification"),
                object: nil,
                queue: .main
            ) { [weak self] notification in  // 错误：结构体中不能使用weak self
                self?.handleNotification(notification)
            }
        }
    }
}
```

**正确代码示例**：
```swift
struct MyView: View {
    var body: some View {
        Button("Tap") {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SomeNotification"),
                object: nil,
                queue: .main
            ) { notification in  // 正确：直接使用self
                self.handleNotification(notification)
            }
        }
    }
}
```

**解决方案**：
- 在结构体中，直接使用`self`而不是`[weak self]`
- 如果确实需要避免循环引用，考虑将相关逻辑移到类中处理

## 2. 重复的属性声明

**错误信息**：
```
Invalid redeclaration of 'propertyName'
```

**问题描述**：  
在类或结构体中重复声明了同名属性，导致编译错误。

**错误代码示例**：
```swift
class ChatMessage {
    var imageData: Data?
    var imageData: Data?  // 错误：重复声明
}
```

**正确代码示例**：
```swift
class ChatMessage {
    var imageData: Data?  // 正确：只声明一次
}
```

**解决方案**：
- 检查代码中是否有重复声明的属性
- 使用代码编辑器的搜索功能查找重复声明

## 3. 条件绑定中使用非可选类型

**错误信息**：
```
Initializer for conditional binding must have Optional type, not 'Type'
```

**问题描述**：  
在`guard let`或`if let`语句中尝试解包一个非可选类型的值，这是不必要的，也是不允许的。

**错误代码示例**：
```swift
func someFunction() {
    let image: CGImage = getCGImage()
    guard let image = image else { return }  // 错误：image不是可选类型
}
```

**正确代码示例**：
```swift
func someFunction() {
    let image: CGImage = getCGImage()
    // 不需要解包，直接使用
}

// 或者，如果getCGImage()返回的是可选类型
func someFunction() {
    guard let image = getCGImage() else { return }  // 正确：解包可选类型
}
```

**解决方案**：
- 只对可选类型使用条件绑定
- 检查变量的类型，确保它是可选类型才进行解包

## 4. 未使用的变量

**错误信息**：
```
Variable 'variableName' was never used
```

**问题描述**：  
声明了一个变量但从未使用它，这会导致编译器警告。

**错误代码示例**：
```swift
func captureScreen() {
    let captureRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    // captureRect从未被使用
}
```

**正确代码示例**：
```swift
func captureScreen() {
    let captureRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    performCapture(in: captureRect)  // 使用变量
}

// 或者，如果确实不需要这个变量
func captureScreen() {
    // 不声明不需要的变量
}
```

**解决方案**：
- 使用声明的变量
- 如果不需要该变量，则不要声明它
- 如果需要声明但不使用（例如API要求），可以使用下划线`_`忽略它

## 5. 在后台线程更新UI

**错误信息**：
```
Publishing changes from background threads is not allowed; make sure to publish values from the main thread
```

**问题描述**：  
在后台线程中更新UI或发布ObservableObject的变化，这在SwiftUI中是不允许的。所有UI更新必须在主线程上进行。

**错误代码示例**：
```swift
class ViewModel: ObservableObject {
    @Published var data: [String] = []
    
    func fetchData() {
        DispatchQueue.global().async {
            // 在后台线程获取数据
            let newData = self.loadData()
            self.data = newData  // 错误：在后台线程更新@Published属性
        }
    }
}
```

**正确代码示例**：
```swift
class ViewModel: ObservableObject {
    @Published var data: [String] = []
    
    func fetchData() {
        DispatchQueue.global().async {
            // 在后台线程获取数据
            let newData = self.loadData()
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.data = newData  // 正确：在主线程更新@Published属性
            }
        }
    }
}
```

**解决方案**：
- 使用`DispatchQueue.main.async`确保UI更新在主线程上执行
- 对于SwiftData操作，也应在主线程上执行