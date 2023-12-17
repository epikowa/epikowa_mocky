# Introduction
This library is a mocking library to help with testing Haxe code.

It currently is very early.

## Why not use an existing one?
I wanted the mocking library to be future-proof.  
As Haxe introduces new features, such as null safety, we need mocking libraries to be able to handle such features and the constraints they introduce.

## How to use

>   [!WARNING]  
>   This library is in very very early stage and not ready at all to be used. This is likely to change.

In order to create a mock:

```haxe
var mock = Mocky.mock(MyClass);
```

If `MyClass` requires type parameters:

```haxe
var mock = Mocky.mock(MyClass, [String, Int]);
```

Calls made to functions on the mock are stored in a `callStore` array:

```haxe
var mock = Mocky.mock(MyClass);
trace(mock.callStore);
```

>   [!Note]  
>   More tracking and convenience methods to interpret it will be added in the future.

>   [!WARNING]  
>   Mocking a function that uses class type parameters isn't currently implemented, making it practically useless for classes that use type parameters. This is obviously planned.