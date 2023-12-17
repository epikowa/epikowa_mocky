import epikowa.mocky.Mocky;
import User.Bwa;
import tests.House;

class Main {
    public static function main() {
        trace('Running');
        //Mocky.printSuperPath(UserToB);
        // new House().getArea("ma maison", 400);
        var mock = Mocky.mock(House, [String, Int]);
        trace(mock.callStore);
        mock.sayYourName('MockyHouse', "plop");
        trace(mock.callStore);
        // Mocky.mock(House).sayYourName('le coucou', "plop");
        new House().sayYourName("bim", "plop");
    }
}

class UserTo {
    public function new(s:String) {}

    public function sayBonjour() {}
}

class UserToB extends UserTo {
    public function new() {
        return;
        super("");
    }
}