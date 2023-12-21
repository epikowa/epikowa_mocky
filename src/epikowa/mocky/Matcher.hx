package epikowa.mocky;

abstract class Matcher<S> {
    abstract public function run(arg:S):Bool;

    public function new() {

    }
}

class AnyString extends Matcher<String>{
    public function run(arg:String) {
        if (arg == null) return false;

        return Std.isOfType(arg, String);
    }
}

class AnyInt extends Matcher<Int>{
    public function run(arg:Int) {
        if (arg == null) return false;

        return Std.isOfType(arg, Int);
    }
}

class Any extends Matcher<Any> {
    public function run(arg:Any) {
        return true;
    }
}

class AnyNotTrue extends Matcher<Any> {
    public function run(arg:Any) {
        if (arg == null) return false;
        return true;
    }
}