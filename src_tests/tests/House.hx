package tests;

class House<S, T> {
    var name(default, never):String;
    
    public function new() {}

    @:nullSafety(Strict)
    public function getArea(name:Null<String>, surface:Int) {
        trace('Original call ${name}');
    }

    public function sayYourName(name:String, thing:String) {
        trace('hi from ${name}');
    }
}
