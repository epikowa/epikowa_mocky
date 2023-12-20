# Introduction
This library is a mocking library to help with testing Haxe code.

It currently is very early.

## Why not use an existing one?
I wanted the mocking library to be future-proof.  
As Haxe introduces new features, such as null safety, we need mocking libraries to be able to handle such features and the constraints they introduce.

## How to use

>   [!WARNING]  
>   This library is in very early stage and does not currently expose a proper testing interface. What is exposed is subject to (heavy) changes.  

In order to create a mock:

```haxe
var mock = Mocky.mock(MyClass);
```

If `MyClass` requires type parameters:

```haxe
var mock = Mocky.mock(MyClass, [String, Int]);
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
