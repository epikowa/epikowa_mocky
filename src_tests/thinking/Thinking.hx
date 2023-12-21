package thinking;

class Thinking {
    var __mocksValues:Array<{
        callName:String,
        paramsMatchers:Array<Matcher<Dynamic>>,
        returnValue:Dynamic
    }> = new Array();

    public function trySomething(s:String, p:Int) {
        var applicableMocks = __mocksValues.filter((mock) -> {
            if (mock.callName != 'trySomething') return false;

            if (mock.paramsMatchers[0].run(s) == false)
                return false;

            if (mock.paramsMatchers[1].run(p) == false)
                return false;

            return true;
        });

        if (applicableMocks.length <0)
            throw 'No applicable mocks';
        
        return applicableMocks[0].returnValue;
    }

    public function __mockCall(callName:String, paramsMatchers:Array<Matcher<Dynamic>>, returnValue:Dynamic) {
        __mocksValues.push({
            callName:callName,
            paramsMatchers:paramsMatchers,
            returnValue:returnValue
        });
    }
}

abstract class Matcher<S> {
    abstract public function run(arg:S):Bool;

    public function new() {

    }
}

class AnyString extends Matcher<String> {
    var expected:String;

    public function new(s:String) {
        super();

        expected = s;
    }

    public function run(arg:String):Bool {
        var s:String = cast (arg, String);
        
        return s == expected;
    }
}