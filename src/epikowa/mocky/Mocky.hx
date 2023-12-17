package epikowa.mocky;

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
        Context.defineType(createDefinitionFromClass(classType, params));
        var newExpr:haxe.macro.Expr = {expr: ENew(classTypeToMockTypePath(classType, params), []), pos: haxe.macro.Context.currentPos()};

        counter++;
        return newExpr;
    }

    macro static public function printSuperPath<T>(toMock:ExprOf<T>) {
        var type = Context.getType(ExprTools.toString(toMock));
        var classType = TypeTools.getClass(type);

        return {expr: EConst(CIdent("null")), pos: haxe.macro.Context.currentPos()};
    }

    #if macro
    static function createDefinitionFromClass<T>(classType:haxe.macro.Type.ClassType, ?params: haxe.macro.Expr.ExprOf<Array<T>>):TypeDefinition {
        var pack = Lambda.concat(['mockymocks'], classType.module.split('.'));

        var fields = new Array<Field>();
        fields.push(generateCallStore());

        for (f in classType.fields.get()) {
            if (f.name != 'new') {
                var newF = mockField(f);
                if (newF != null) fields.push(newF);
            }
        }

        fields.push(generateConstructor(params));

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
                    params.push(TypeParam.TPType(TypeTools.toComplexType(Context.getType(identifier))));
                }

                params;
            default:
                throw 'Incorrect kind of type parameters : ${params.expr.getName()}';
        }: null;

        return {
            params: classType.params.map(p -> {
                params: [],
                name: p.name,
                constraints: [],
                meta: null,
                defaultType: p.defaultType != null ? TypeTools.toComplexType(p.defaultType) : null
            }),
            pack: pack,
            fields: fields,
            kind: TypeDefKind.TDClass({name: classType.module.split('.').pop(), pack: classType.pack, sub: classType.name, params: superTypeParams}),
            pos: Context.currentPos(),
            name: '${classType.name}_MockyMock_${counter}'
        }
    }

    static function classTypeToTypePath(classType:haxe.macro.Type.ClassType):TypePath {
        return {
            pack: classType.pack,
            name: classType.name,
            sub: classType.module
        };
    }

    static function mockField(field:ClassField):Field {
        var prepareArg = function (args:{name:String, opt:Bool, t:haxe.macro.Type}):FunctionArg {
            return {
                name: args.name,
                type: TypeTools.toComplexType(args.t),
                opt: args.opt
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
                        for (param in paramsNames) {
                            pp.push(macro data.push($i{param}));
                        };

                        return {
                            access: [AOverride],
                            name: field.name,
                            doc: field.doc,
                            meta: field.meta.get(),
                            pos: Context.currentPos(),
                            kind:  FFun({
                                args: preparedArgs,
                                expr: macro { 
                                    {
                                        trace('Mocked function');
                                        var data = new Array<Dynamic>();
                                        $b{pp};
                                        callStore.push({name: $v{field.name}, params: data});
                                        return; 
                                    }
                                },
                                params: []
                            })
                        };
                    default:
                        trace('Unmatched thing for field ${field.name} (${field.type.getName()})');
                }
        }

        return null;
    }

    static function generateConstructor<T>(?params: haxe.macro.Expr.ExprOf<Array<T>>):Field {
        return {
            name: 'new',
            pos: Context.currentPos(),
            access: [APublic],
            kind: FFun({args: [], expr: macro ${macro {var a = "test"; return; super(); }}})
        };
    }

    static function generateCallStore():Field {
        return {
            name: 'callStore',
            pos: Context.currentPos(),
            access: [APublic],
            kind: FVar(macro :Array<{name: String, params:Array<Dynamic>}>, macro new Array())
        };
    }

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