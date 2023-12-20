import epikowa.mocky.Mocky;
import tests.House;

typedef Plop = Int;
typedef TestGenMock = Array<TestGen<String>>;
class Main {
    public static function main() {
        trace('Running');
        var testValue = new TestGenMock();
        var mock = Mocky.mock(House, [TestGenMock, Int]);
        mock.sayYourName(testValue, '');
        mock.getArea('original name', 12);
        trace(mock.callStore);
        // new House().sayYourName("bim", "plop");
    }
}

class TestGen<S> {
    public function new() {}

    public function something(param):S {
        return param;
    }
}