package tests;

class House<S, T> {
    var name(default, never):String;
    
    public function new() {}

    @:nullSafety(Strict)
    public function getArea(name:Null<String>, surface:Int):Dynamic {
        trace('Original call ${name}');
        throw 'Exception is being returned';
        return name + ' has been returned';
    }

    public function sayYourName(name:S, thing:String) {
        trace('hi from ${name}');
        // throw 'Second exception!';
    }
}
