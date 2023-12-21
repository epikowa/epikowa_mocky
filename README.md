# Introduction
This library is a mocking library to help with testing Haxe code.

It currently is very early.

## Why not use an existing one?
I wanted the mocking library to be future-proof.  
As Haxe introduces new features, such as null safety, we need mocking libraries to be able to handle such features and the constraints they introduce.

## How to use

>   [!WARNING]  
>   This library is in very early stage and does not currently expose a proper testing interface. What is exposed is subject to (heavy) changes.  

>   [!Note]  
>   At the moment, only spying is supported.  
>   That means the "mocked" function will in fact always be called. 
>   Actual mocking will be available soon.

### Creating a spy
In order to create a spy:

```haxe
var mock = Mocky.mock(MyClass, false);
```

If `MyClass` requires type parameters:

```haxe
var mock = Mocky.mock(MyClass, [String, Int], false);
```

If one of your type parameters expects types parameters itself, you should use a typedef:

```haxe
typedef ExpectedArrayType = Array<String>;
class {
    function test() {
        var mock = Mocky.mock(MyClass, [ExpectedArrayType]);
    }
}
```

### Creating a mock
In order to create a mock:

```haxe
var mock = Mocky.mock(MyClass, true);
```

If `MyClass` requires type parameters:

```haxe
var mock = Mocky.mock(MyClass, [String, Int], true);
```

If one of your type parameters expects types parameters itself, you should use a typedef:

```haxe
typedef ExpectedArrayType = Array<String>;
class {
    function test() {
        var mock = Mocky.mock(MyClass, [ExpectedArrayType]);
    }
}
```

You then have to add values that are going to be returned when particular `Matcher` (see `epikowa.mocky.Matcher`) return `true` for given arguments:

```haxe
mock.__mockCall(
    'sayYourName', //mocked function's name
    [new AnyString(),
    new AnyString()],
    "this is a mocked return value"
);
```

### Checking calls  
Calls made to functions on the mock are stored in a `callStore` array:

```haxe
var mock = Mocky.mock(MyClass);
trace(mock.callStore);
```

The type of callStore is as follows:

```haxe
    Array<{
        name: String, //function's name
        params: Array<Dynamic>, //passed parameters
        returnedValue: Dynamic,
        thrownException: Dynamic
    }>
```

>   [!Note]  
>   More tracking and convenience methods to interpret it will be added in the future.
