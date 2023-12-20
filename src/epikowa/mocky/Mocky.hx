package epikowa.mocky;

import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.TypeParamDecl;
import haxe.macro.Expr.ExprDef;
import haxe.macro.Expr.TypeParam;
import haxe.macro.Type;
import haxe.macro.Expr.FieldType;
import haxe.macro.Type.FieldKind;
import haxe.macro.Expr.FunctionArg;
import haxe.macro.Type.ClassField;
import haxe.macro.Expr.Field;
import haxe.macro.Type.TFunc;
import haxe.macro.Type.ClassType;
import haxe.macro.Expr.TypePath;
import haxe.macro.Type.ClassKind;
import haxe.macro.Expr.TypeDefinition;
import haxe.macro.Expr.TypeDefKind;
import haxe.macro.Expr.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.ExprTools;

@:nullSafety(StrictThreaded)
class Mocky {
    static var counter:Int = 0;

    public static function regCall(something:Dynamic) {
        return null;
    }

    macro public static function mock<T>(toMock:ExprOf<T>, ?params: haxe.macro.Expr.ExprOf<Array<T>>):ExprOf<T> {
        var type = Context.getType(ExprTools.toString(toMock));
        var classType = TypeTools.getClass(type);
        var mockyCreator = new MockyCreator(classType, params);
        Context.defineType(mockyCreator.createDefinitionFromClass());
        var newExpr:haxe.macro.Expr = {expr: ENew(classTypeToMockTypePath(classType, params), []), pos: haxe.macro.Context.currentPos()};

        counter++;
        return newExpr;
    }

    #if macro

    static function classTypeToMockTypePath<T>(classType:ClassType, params: haxe.macro.Expr.ExprOf<Array<T>>):TypePath {
        var pack = Lambda.concat(['mockymocks'], classType.pack);
 
        return {
            pack: pack,
            sub: '${classType.name}_MockyMock_${counter}',
            name: classType.module.split('.').pop(),
            params: params != null ? switch(params.expr) {
                case EArrayDecl(values):
                    var params = [];

                    for (value in values) {
                        var identifier = ExprTools.toString(value);
                        params.push(TypeParam.TPType(TypeTools.toComplexType(Context.getType(identifier))));
                    }

                    params;
                default:
                    throw 'Incorrect kind of type parameters (classTypeToMockTypePath) : ${params.expr.getName()}';
            }: null
        };
    }
    #end
}

#if macro
@:nullSafety(Strict)
class MockyCreator<T> {
    var classType:haxe.macro.Type.ClassType;
    var params: Null<haxe.macro.Expr.ExprOf<Array<T>>>;
    var genericsMap:Map<String, ComplexType>;

    public function new(classType:haxe.macro.Type.ClassType, ?params: haxe.macro.Expr.ExprOf<Array<T>>) {
        genericsMap = new Map();
        this.classType = classType;
        this.params = params;
        generateGenericsMap();
    }

    function generateGenericsMap() {
        var i = 0;
        var paramsArray = [];

        switch(params.expr) {
            case EArrayDecl(values):

                for (value in values) {
                    var identifier = ExprTools.toString(value);
                    paramsArray.push(TypeTools.toComplexType(Context.getType(identifier)));
                }
            default:
                throw 'Incorrect kind of type parameters : ${params.expr.getName()}';
        }

        for (param in classType.params) {
            var genericsName = TypeTools.toString(param.t);
            var complexType = paramsArray[i];
            genericsMap.set(genericsName, complexType);
            i++;
        }
    }
    
    @:access(epikowa.mocky.Mocky.createDefinitionFromClass)
    public function createDefinitionFromClass() {
        return createDefinitionFromClassImpl();
    }
    
    @:access(epikowa.mocky.Mocky.counter)
    function createDefinitionFromClassImpl():TypeDefinition {
        var pack = Lambda.concat(['mockymocks'], classType.module.split('.'));

        var fields = new Array<Field>();
        fields.push(generateCallStore());

        for (f in classType.fields.get()) {
            if (f.name != 'new') {
                var newF = mockField(f);
                if (newF != null) fields.push(newF);
            }
        }

        fields.push(generateConstructor());

        var typeParams = [];

        if (params != null) {
            switch (params.expr) {
                case EArrayDecl(values):
                    for (value in values) {
                        var identifier = ExprTools.toString(value);
                        typeParams.push(TypeTools.toComplexType(Context.getType(identifier)));
                    }
                default:
            }
        }

        var superTypeParams = params != null ? switch(params.expr) {
            case EArrayDecl(values):
                var params = [];

                for (value in values) {
                    var identifier = ExprTools.toString(value);
                    var complexType = TypeTools.toComplexType(Context.getType(identifier));
                    params.push(TypeParam.TPType(TypeTools.toComplexType(Context.getType(identifier))));
                }

                params;
            default:
                throw 'Incorrect kind of type parameters : ${params.expr.getName()}';
        }: null;
        
        return {
            params: classType.params.map(p -> typeParameterToTypeParameterDecl(p)),
            pack: pack,
            fields: fields,
            kind: TypeDefKind.TDClass({name: classType.module.split('.').pop(), pack: classType.pack, sub: classType.name, params: superTypeParams}),
            pos: Context.currentPos(),
            name: '${classType.name}_MockyMock_${Mocky.counter}'
        }
    }

    function generateCallStore():Field {
        return {
            name: 'callStore',
            pos: Context.currentPos(),
            access: [APublic],
            kind: FVar(macro :Array<{name: String, params:Array<Dynamic>, returnedValue: Dynamic}>, macro new Array())
        };
    }

    function generateConstructor():Field {
        return {
            name: 'new',
            pos: Context.currentPos(),
            access: [APublic],
            kind: FFun({args: [], expr: macro ${macro {var a = "test"; return; super(); }}})
        };
    }

    function typeParameterToTypeParameterDecl(typeParameter:TypeParameter) {
        switch (typeParameter.t) {
            case TInst(t, params):
                $type(t);
                $type(params);
            default:
                throw 'Unsupported kind of type parameter (${typeParameter.t.getName()})';
        }
        return {
            params: [], //Improve
            name: typeParameter.name,
            constraints: [],
            meta: null,
            defaultType: typeParameter.defaultType != null ? TypeTools.toComplexType(typeParameter.defaultType) : null
        };
    }

    function mockField(field:ClassField):Field {
        var prepareArg = function (args:{name:String, opt:Bool, t:haxe.macro.Type}):FunctionArg {
            var targetType = if (genericsMap.exists(TypeTools.toString(args.t))) {
                genericsMap.get(TypeTools.toString(args.t));
            } else {
                TypeTools.toComplexType(args.t);
            };
            return {
                name: args.name,
                type: targetType,
                opt: args.opt,
            };
        };

        switch (field.kind) {
            case FVar(read, write):
                trace('*** ${field.name}: ${read.getName()}, ${write.getName()}');
            case FMethod(k):
                switch(field.type) {
                    case TFun(args, ret):
                        var preparedArgs = args.map(prepareArg);

                        var paramsNames = args.map((arg) -> arg.name);
                        var pp = new Array<Expr>();
                        var toBeArgs = new Array<Expr>();
                        for (param in paramsNames) {                            
                            pp.push(macro data.push($i{param}));
                            toBeArgs.push(macro $i{param});
                        };

                        for (param in paramsNames) {
                        }

                        var fieldName = field.name;
                        trace(ret);

                        var isVoidReturn = switch (ret) {
                            case TAbstract(t, params):
                                t.toString() == 'Void';
                                true;
                            default:
                                false;
                        }

                        var expr:Expr;
                        if (!isVoidReturn) {
                            expr = macro { 
                                {
                                    trace('Mocked function');
                                    var data = new Array<Dynamic>();
                                    $b{pp};
                                    var returnedValue:Dynamic = null;
                                    returnedValue = super.$fieldName($a{toBeArgs});
                                    callStore.push({name: $v{field.name}, params: data, returnedValue: returnedValue});
                                    return null; 
                                }
                           }
                        } else {
                            expr = macro {
                                {
                                    trace('Mocked function');
                                    var data = new Array<Dynamic>();
                                    $b{pp};
                                    super.$fieldName($a{toBeArgs});
                                    callStore.push({name: $v{field.name}, params: data, returnedValue: null});
                                    return; 
                                }
                            }
                        }
                        return {
                            access: [AOverride],
                            name: field.name,
                            doc: field.doc,
                            meta: field.meta.get(),
                            pos: Context.currentPos(),
                            kind:  FFun({
                                args: preparedArgs,
                                expr: expr,
                                ret: TypeTools.toComplexType(ret),
                                params: []
                            })
                        };
                    default:
                        trace('Unmatched thing for field ${field.name} (${field.type.getName()})');
                }
        }

        return null;
    }
}
#end