package tests;

class House<S, T> {
    var name(default, never):String;
    
    public function new() {}

    @:nullSafety(Strict)
    public function getArea(name:Null<String>, surface:Int) {
        trace('Original call ${name}');
    }

    public function sayYourName(name:S, thing:String) {
        trace('hi from ${name}');
    }
}

class SubHouse extends House<String, Int> {
    override public function sayYourName(name:String, thing:String) {

    }
}