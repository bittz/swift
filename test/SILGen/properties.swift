
// RUN: %target-swift-emit-silgen -module-name properties -Xllvm -sil-full-demangle -parse-as-library -disable-objc-attr-requires-foundation-module -enable-objc-interop %s | %FileCheck %s

var zero: Int = 0

func use(_: Int) {}
func use(_: Double) {}
func getInt() -> Int { return zero }

// CHECK-LABEL: sil hidden [ossa] @{{.*}}physical_tuple_lvalue
// CHECK: bb0(%0 : $Int):
func physical_tuple_lvalue(_ c: Int) {
  var x : (Int, Int)
  // CHECK: [[BOX:%[0-9]+]] = alloc_box ${ var (Int, Int) }
  // CHECK: [[MARKED_BOX:%[0-9]+]] = mark_uninitialized [var] [[BOX]]
  // CHECK: [[XADDR:%.*]] = project_box [[MARKED_BOX]]
  x.1 = c
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[XADDR]]
  // CHECK: [[X_1:%[0-9]+]] = tuple_element_addr [[WRITE]] : {{.*}}, 1
  // CHECK: assign %0 to [[X_1]]
}

func tuple_rvalue() -> (Int, Int) {}

// CHECK-LABEL: sil hidden [ossa] @{{.*}}physical_tuple_rvalue
func physical_tuple_rvalue() -> Int {
  return tuple_rvalue().1
  // CHECK: [[FUNC:%[0-9]+]] = function_ref @$s10properties12tuple_rvalue{{[_0-9a-zA-Z]*}}F
  // CHECK: [[TUPLE:%[0-9]+]] = apply [[FUNC]]()
  // CHECK: ({{%.*}}, [[RET:%[0-9]+]]) = destructure_tuple [[TUPLE]]
  // CHECK: return [[RET]]
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties16tuple_assignment{{[_0-9a-zA-Z]*}}F
func tuple_assignment(_ a: inout Int, b: inout Int) {
  // CHECK: bb0([[A_ADDR:%[0-9]+]] : $*Int, [[B_ADDR:%[0-9]+]] : $*Int):
  // CHECK: [[READ:%.*]] = begin_access [read] [unknown] [[B_ADDR]]
  // CHECK: [[B:%[0-9]+]] = load [trivial] [[READ]]
  // CHECK: [[READ:%.*]] = begin_access [read] [unknown] [[A_ADDR]]
  // CHECK: [[A:%[0-9]+]] = load [trivial] [[READ]]
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[A_ADDR]]
  // CHECK: assign [[B]] to [[WRITE]]
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[B_ADDR]]
  // CHECK: assign [[A]] to [[WRITE]]
  (a, b) = (b, a)
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties18tuple_assignment_2{{[_0-9a-zA-Z]*}}F
func tuple_assignment_2(_ a: inout Int, b: inout Int, xy: (Int, Int)) {
  // CHECK: bb0([[A_ADDR:%[0-9]+]] : $*Int, [[B_ADDR:%[0-9]+]] : $*Int, [[X:%[0-9]+]] : $Int, [[Y:%[0-9]+]] : $Int):
  (a, b) = xy
  // CHECK: [[XY2:%[0-9]+]] = tuple ([[X]] : $Int, [[Y]] : $Int)
  // CHECK: ([[X:%[0-9]+]], [[Y:%[0-9]+]]) = destructure_tuple [[XY2]]
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[A_ADDR]]
  // CHECK: assign [[X]] to [[WRITE]]
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[B_ADDR]]
  // CHECK: assign [[Y]] to [[WRITE]]
}

class Ref {
  var x, y : Int
  var ref : Ref

  var z: Int { get {} set {} }

  var val_prop: Val { get {} set {} }

  subscript(i: Int) -> Float { get {} set {} }

  init(i: Int) {
    x = i
    y = i
    ref = self
  }
}

class RefSubclass : Ref {
  var w : Int

  override init (i: Int) {
    w = i
    super.init(i: i)
  }
}

struct Val {
  var x, y : Int
  var ref : Ref

  var z: Int { get {} set {} }

  var z_tuple: (Int, Int) { get {} set {} }

  subscript(i: Int) -> Float { get {} set {} }
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties22physical_struct_lvalue{{[_0-9a-zA-Z]*}}F
func physical_struct_lvalue(_ c: Int) {
  var v : Val
  // CHECK: [[VADDR:%[0-9]+]] = alloc_box ${ var Val }
  v.y = c
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown]
  // CHECK: [[YADDR:%.*]] = struct_element_addr [[WRITE]]
  // CHECK: assign %0 to [[YADDR]]
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties21physical_class_lvalue{{[_0-9a-zA-Z]*}}F : $@convention(thin) (@guaranteed Ref, Int) -> ()
// CHECK: bb0([[ARG0:%.*]] : @guaranteed $Ref,
 func physical_class_lvalue(_ r: Ref, a: Int) {
    r.y = a
   // CHECK: [[FN:%[0-9]+]] = class_method [[ARG0]] : $Ref, #Ref.y!setter.1
   // CHECK: apply [[FN]](%1, [[ARG0]]) : $@convention(method) (Int, @guaranteed Ref) -> ()
  }


// CHECK-LABEL: sil hidden [ossa] @$s10properties24physical_subclass_lvalue{{[_0-9a-zA-Z]*}}F
func physical_subclass_lvalue(_ r: RefSubclass, a: Int) {
  // CHECK: bb0([[ARG1:%.*]] : @guaranteed $RefSubclass, [[ARG2:%.*]] : $Int):
  r.y = a
  // CHECK: [[ARG1_COPY:%.*]] = copy_value [[ARG1]] : $RefSubclass
  // CHECK: [[R_SUP:%[0-9]+]] = upcast [[ARG1_COPY]] : $RefSubclass to $Ref
  // CHECK: [[FN:%[0-9]+]] = class_method [[R_SUP]] : $Ref, #Ref.y!setter.1 : (Ref) -> (Int) -> (), $@convention(method) (Int, @guaranteed Ref) -> ()
  // CHECK: apply [[FN]]([[ARG2]], [[R_SUP]]) :
  // CHECK: destroy_value [[R_SUP]]
  r.w = a

  // CHECK: [[FN:%[0-9]+]] = class_method [[ARG1]] : $RefSubclass, #RefSubclass.w!setter.1
  // CHECK: apply [[FN]](%1, [[ARG1]]) : $@convention(method) (Int, @guaranteed RefSubclass) -> ()
  // CHECK-NOT: destroy_value [[ARG1]]
  // CHECK: } // end sil function '$s10properties24physical_subclass_lvalue{{[_0-9a-zA-Z]*}}F'
}
  


func struct_rvalue() -> Val {}

// CHECK-LABEL: sil hidden [ossa] @$s10properties22physical_struct_rvalue{{[_0-9a-zA-Z]*}}F
func physical_struct_rvalue() -> Int {
  return struct_rvalue().y
  // CHECK: [[FUNC:%[0-9]+]] = function_ref @$s10properties13struct_rvalueAA3ValVyF
  // CHECK: [[STRUCT:%[0-9]+]] = apply [[FUNC]]()
  // CHECK: [[BORROWED_STRUCT:%.*]] = begin_borrow [[STRUCT]]
  // CHECK: [[RET:%[0-9]+]] = struct_extract [[BORROWED_STRUCT]] : $Val, #Val.y
  // CHECK: end_borrow [[BORROWED_STRUCT]]
  // CHECK: destroy_value [[STRUCT]]
  // CHECK: return [[RET]]
}

func class_rvalue() -> Ref {}

// CHECK-LABEL: sil hidden [ossa] @$s10properties21physical_class_rvalue{{[_0-9a-zA-Z]*}}F
func physical_class_rvalue() -> Int {
  return class_rvalue().y
  // CHECK: [[FUNC:%[0-9]+]] = function_ref @$s10properties12class_rvalueAA3RefCyF
  // CHECK: [[CLASS:%[0-9]+]] = apply [[FUNC]]()
  // CHECK: [[BORROW:%.*]] = begin_borrow [[CLASS]]
  // CHECK: [[FN:%[0-9]+]] = class_method [[BORROW]] : $Ref, #Ref.y!getter.1
  // CHECK: [[RET:%[0-9]+]] = apply [[FN]]([[BORROW]])
  // CHECK: return [[RET]]
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties18logical_struct_get{{[_0-9a-zA-Z]*}}F
func logical_struct_get() -> Int {
  return struct_rvalue().z
  // CHECK: [[GET_RVAL:%[0-9]+]] = function_ref @$s10properties13struct_rvalue{{[_0-9a-zA-Z]*}}F
  // CHECK: [[STRUCT:%[0-9]+]] = apply [[GET_RVAL]]()
  // CHECK: [[BORROW:%[0-9]+]] = begin_borrow [[STRUCT]]
  // CHECK: [[GET_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV1z{{[_0-9a-zA-Z]*}}vg
  // CHECK: [[VALUE:%[0-9]+]] = apply [[GET_METHOD]]([[BORROW]])
  // CHECK: return [[VALUE]]
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties18logical_struct_set{{[_0-9a-zA-Z]*}}F
func logical_struct_set(_ value: inout Val, z: Int) {
  // CHECK: bb0([[VAL:%[0-9]+]] : $*Val, [[Z:%[0-9]+]] : $Int):
  value.z = z
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[VAL]]
  // CHECK: [[Z_SET_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV1z{{[_0-9a-zA-Z]*}}vs
  // CHECK: apply [[Z_SET_METHOD]]([[Z]], [[WRITE]])
  // CHECK: return
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties27logical_struct_in_tuple_set{{[_0-9a-zA-Z]*}}F
func logical_struct_in_tuple_set(_ value: inout (Int, Val), z: Int) {
  // CHECK: bb0([[VAL:%[0-9]+]] : $*(Int, Val), [[Z:%[0-9]+]] : $Int):
  value.1.z = z
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[VAL]]
  // CHECK: [[VAL_1:%[0-9]+]] = tuple_element_addr [[WRITE]] : {{.*}}, 1
  // CHECK: [[Z_SET_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV1z{{[_0-9a-zA-Z]*}}vs
  // CHECK: apply [[Z_SET_METHOD]]([[Z]], [[VAL_1]])
  // CHECK: return
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties29logical_struct_in_reftype_set{{[_0-9a-zA-Z]*}}F
func logical_struct_in_reftype_set(_ value: inout Val, z1: Int) {
  // CHECK: bb0([[VAL:%[0-9]+]] : $*Val, [[Z1:%[0-9]+]] : $Int):
  value.ref.val_prop.z_tuple.1 = z1
  // -- val.ref
  // CHECK: [[READ:%.*]] = begin_access [read] [unknown] [[VAL]]
  // CHECK: [[VAL_REF_ADDR:%[0-9]+]] = struct_element_addr [[READ]] : $*Val, #Val.ref
  // CHECK: [[VAL_REF:%[0-9]+]] = load [copy] [[VAL_REF_ADDR]]
  // -- getters and setters
  // -- val.ref.val_prop
  // CHECK: [[BORROW:%.*]] = begin_borrow [[VAL_REF]]
  // CHECK: [[MAT_VAL_PROP_METHOD:%[0-9]+]] = class_method {{.*}} : $Ref, #Ref.val_prop!modify.1 : (Ref) -> ()
  // CHECK: ([[VAL_REF_VAL_PROP_MAT:%[0-9]+]], [[TOKEN:%.*]]) = begin_apply [[MAT_VAL_PROP_METHOD]]([[BORROW]])
  // -- val.ref.val_prop.z_tuple
  // CHECK: [[V_R_VP_Z_TUPLE_MAT:%[0-9]+]] = alloc_stack $(Int, Int)
  // CHECK: [[LD:%[0-9]+]] = load_borrow [[VAL_REF_VAL_PROP_MAT]]
  // CHECK: [[A0:%.*]] = tuple_element_addr [[V_R_VP_Z_TUPLE_MAT]] : {{.*}}, 0
  // CHECK: [[A1:%.*]] = tuple_element_addr [[V_R_VP_Z_TUPLE_MAT]] : {{.*}}, 1
  // CHECK: [[GET_Z_TUPLE_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV7z_tupleSi_Sitvg
  // CHECK: [[V_R_VP_Z_TUPLE:%[0-9]+]] = apply [[GET_Z_TUPLE_METHOD]]([[LD]])
  // CHECK: ([[T0:%.*]], [[T1:%.*]]) = destructure_tuple [[V_R_VP_Z_TUPLE]]
  // CHECK: store [[T0]] to [trivial] [[A0]]
  // CHECK: store [[T1]] to [trivial] [[A1]]
  // CHECK: end_borrow [[LD]]
  // -- write to val.ref.val_prop.z_tuple.1
  // CHECK: [[V_R_VP_Z_TUPLE_1:%[0-9]+]] = tuple_element_addr [[V_R_VP_Z_TUPLE_MAT]] : {{.*}}, 1
  // CHECK: assign [[Z1]] to [[V_R_VP_Z_TUPLE_1]]
  // -- writeback to val.ref.val_prop.z_tuple
  // CHECK: [[WB_V_R_VP_Z_TUPLE:%[0-9]+]] = load [trivial] [[V_R_VP_Z_TUPLE_MAT]]
  // CHECK: [[SET_Z_TUPLE_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV7z_tupleSi_Sitvs
  // CHECK: apply [[SET_Z_TUPLE_METHOD]]({{%[0-9]+, %[0-9]+}}, [[VAL_REF_VAL_PROP_MAT]])
  // -- writeback to val.ref.val_prop
  // CHECK: end_apply [[TOKEN]]
  // -- cleanup
  // CHECK: dealloc_stack [[V_R_VP_Z_TUPLE_MAT]]
  // -- don't need to write back to val.ref because it's a ref type
}

func reftype_rvalue() -> Ref {}

// CHECK-LABEL: sil hidden [ossa] @$s10properties18reftype_rvalue_set{{[_0-9a-zA-Z]*}}F
func reftype_rvalue_set(_ value: Val) {
  reftype_rvalue().val_prop = value
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties27tuple_in_logical_struct_set{{[_0-9a-zA-Z]*}}F
func tuple_in_logical_struct_set(_ value: inout Val, z1: Int) {
  // CHECK: bb0([[VAL:%[0-9]+]] : $*Val, [[Z1:%[0-9]+]] : $Int):
  value.z_tuple.1 = z1
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[VAL]]
  // CHECK: [[Z_TUPLE_MATERIALIZED:%[0-9]+]] = alloc_stack $(Int, Int)
  // CHECK: [[VAL1:%[0-9]+]] = load_borrow [[WRITE]]
  // CHECK: [[A0:%.*]] = tuple_element_addr [[Z_TUPLE_MATERIALIZED]] : {{.*}}, 0
  // CHECK: [[A1:%.*]] = tuple_element_addr [[Z_TUPLE_MATERIALIZED]] : {{.*}}, 1
  // CHECK: [[Z_GET_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV7z_tupleSi_Sitvg
  // CHECK: [[Z_TUPLE:%[0-9]+]] = apply [[Z_GET_METHOD]]([[VAL1]])
  // CHECK: ([[T0:%.*]], [[T1:%.*]]) = destructure_tuple [[Z_TUPLE]]
  // CHECK: store [[T0]] to [trivial] [[A0]]
  // CHECK: store [[T1]] to [trivial] [[A1]]
  // CHECK: end_borrow [[VAL1]]
  // CHECK: [[Z_TUPLE_1:%[0-9]+]] = tuple_element_addr [[Z_TUPLE_MATERIALIZED]] : {{.*}}, 1
  // CHECK: assign [[Z1]] to [[Z_TUPLE_1]]
  // CHECK: [[Z_TUPLE_MODIFIED:%[0-9]+]] = load [trivial] [[Z_TUPLE_MATERIALIZED]]
  // CHECK: [[Z_SET_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV7z_tupleSi_Sitvs
  // CHECK: apply [[Z_SET_METHOD]]({{%[0-9]+, %[0-9]+}}, [[WRITE]])
  // CHECK: dealloc_stack [[Z_TUPLE_MATERIALIZED]]
  // CHECK: return
}

var global_prop : Int {
  // CHECK-LABEL: sil hidden [ossa] @$s10properties11global_prop{{[_0-9a-zA-Z]*}}vg
  get {
    return zero
  }
  // CHECK-LABEL: sil hidden [ossa] @$s10properties11global_prop{{[_0-9a-zA-Z]*}}vs
  set {
    use(newValue)
  }
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties18logical_global_get{{[_0-9a-zA-Z]*}}F
func logical_global_get() -> Int {
  return global_prop
  // CHECK: [[GET:%[0-9]+]] = function_ref @$s10properties11global_prop{{[_0-9a-zA-Z]*}}vg
  // CHECK: [[VALUE:%[0-9]+]] = apply [[GET]]()
  // CHECK: return [[VALUE]]
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties18logical_global_set{{[_0-9a-zA-Z]*}}F
func logical_global_set(_ x: Int) {
  global_prop = x
  // CHECK: [[SET:%[0-9]+]] = function_ref @$s10properties11global_prop{{[_0-9a-zA-Z]*}}vs
  // CHECK: apply [[SET]](%0)
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties17logical_local_get{{[_0-9a-zA-Z]*}}F
func logical_local_get(_ x: Int) -> Int {
  var prop : Int {
    get {
      return x
    }
  }
  // CHECK: [[GET_REF:%[0-9]+]] = function_ref [[PROP_GET_CLOSURE:@\$s10properties17logical_local_getyS2iF4propL_Sivg]]
  // CHECK: apply [[GET_REF]](%0)
  return prop
}
// CHECK-: sil private [[PROP_GET_CLOSURE]]
// CHECK: bb0(%{{[0-9]+}} : $Int):

func logical_generic_local_get<T>(_ x: Int, _: T) {
  var prop1: Int {
    get {
      return x
    }
  }

  _ = prop1

  var prop2: Int {
    get {
      _ = T.self
      return x
    }
  }

  _ = prop2
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties26logical_local_captured_get{{[_0-9a-zA-Z]*}}F
func logical_local_captured_get(_ x: Int) -> Int {
  var prop : Int {
    get {
      return x
    }
  }
  func get_prop() -> Int {
    return prop
  }

  return get_prop()
  // CHECK: [[FUNC_REF:%[0-9]+]] = function_ref @$s10properties26logical_local_captured_getyS2iF0E5_propL_SiyF
  // CHECK: apply [[FUNC_REF]](%0)
}
// CHECK: sil private [ossa] @$s10properties26logical_local_captured_get{{.*}}vg
// CHECK: bb0(%{{[0-9]+}} : $Int):

func inout_arg(_ x: inout Int) {}

// CHECK-LABEL: sil hidden [ossa] @$s10properties14physical_inout{{[_0-9a-zA-Z]*}}F
func physical_inout(_ x: Int) {
  var x = x
  // CHECK: [[XADDR:%[0-9]+]] = alloc_box ${ var Int }
  // CHECK: [[PB:%.*]] = project_box [[XADDR]]
  inout_arg(&x)
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[PB]]
  // CHECK: [[INOUT_ARG:%[0-9]+]] = function_ref @$s10properties9inout_arg{{[_0-9a-zA-Z]*}}F
  // CHECK: apply [[INOUT_ARG]]([[WRITE]])
}


/* TODO check writeback to more complex logical prop, check that writeback
 * reuses temporaries */

// CHECK-LABEL: sil hidden [ossa] @$s10properties17val_subscript_get{{[_0-9a-zA-Z]*}}F : $@convention(thin) (@guaranteed Val, Int) -> Float
// CHECK: bb0([[VVAL:%[0-9]+]] : @guaranteed $Val, [[I:%[0-9]+]] : $Int):
func val_subscript_get(_ v: Val, i: Int) -> Float {
  return v[i]
  // CHECK: [[SUBSCRIPT_GET_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV{{[_0-9a-zA-Z]*}}ig
  // CHECK: [[RET:%[0-9]+]] = apply [[SUBSCRIPT_GET_METHOD]]([[I]], [[VVAL]]) : $@convention(method) (Int, @guaranteed Val)
  // CHECK: return [[RET]]
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties17val_subscript_set{{[_0-9a-zA-Z]*}}F
// CHECK: bb0(%0 : @guaranteed $Val, [[I:%[0-9]+]] : $Int, [[X:%[0-9]+]] : $Float):
func val_subscript_set(_ v: Val, i: Int, x: Float) {
  var v = v
  v[i] = x
  // CHECK: [[VADDR:%[0-9]+]] = alloc_box ${ var Val }
  // CHECK: [[PB:%.*]] = project_box [[VADDR]]
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[PB]]
  // CHECK: [[SUBSCRIPT_SET_METHOD:%[0-9]+]] = function_ref @$s10properties3ValV{{[_0-9a-zA-Z]*}}is
  // CHECK: apply [[SUBSCRIPT_SET_METHOD]]([[X]], [[I]], [[WRITE]])
}

struct Generic<T> {
  var mono_phys:Int
  var mono_log: Int { get {} set {} }
  var typevar_member:T

  subscript(x: Int) -> Float { get {} set {} }

  subscript(x: T) -> T { get {} set {} }

  // CHECK-LABEL: sil hidden [ossa] @$s10properties7GenericV19copy_typevar_member{{[_0-9a-zA-Z]*}}F
  mutating
  func copy_typevar_member(_ x: Generic<T>) {
    typevar_member = x.typevar_member
  }
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties21generic_mono_phys_get{{[_0-9a-zA-Z]*}}F
func generic_mono_phys_get<T>(_ g: Generic<T>) -> Int {
  return g.mono_phys
  // CHECK: struct_element_addr %{{.*}}, #Generic.mono_phys
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties20generic_mono_log_get{{[_0-9a-zA-Z]*}}F
func generic_mono_log_get<T>(_ g: Generic<T>) -> Int {
  return g.mono_log
  // CHECK: [[GENERIC_GET_METHOD:%[0-9]+]] = function_ref @$s10properties7GenericV8mono_log{{[_0-9a-zA-Z]*}}vg
  // CHECK: apply [[GENERIC_GET_METHOD]]<
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties20generic_mono_log_set{{[_0-9a-zA-Z]*}}F
func generic_mono_log_set<T>(_ g: Generic<T>, x: Int) {
  var g = g
  g.mono_log = x
  // CHECK: [[GENERIC_SET_METHOD:%[0-9]+]] = function_ref @$s10properties7GenericV8mono_log{{[_0-9a-zA-Z]*}}vs
  // CHECK: apply [[GENERIC_SET_METHOD]]<
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties26generic_mono_subscript_get{{[_0-9a-zA-Z]*}}F
func generic_mono_subscript_get<T>(_ g: Generic<T>, i: Int) -> Float {
  return g[i]
  // CHECK: [[GENERIC_GET_METHOD:%[0-9]+]] = function_ref @$s10properties7GenericV{{[_0-9a-zA-Z]*}}ig
  // CHECK: apply [[GENERIC_GET_METHOD]]<
}

// CHECK-LABEL: sil hidden [ossa] @{{.*}}generic_mono_subscript_set
func generic_mono_subscript_set<T>(_ g: inout Generic<T>, i: Int, x: Float) {
  g[i] = x
  // CHECK: [[GENERIC_SET_METHOD:%[0-9]+]] = function_ref @$s10properties7GenericV{{[_0-9a-zA-Z]*}}is
  // CHECK: apply [[GENERIC_SET_METHOD]]<
}

// CHECK-LABEL: sil hidden [ossa] @{{.*}}bound_generic_mono_phys_get
func bound_generic_mono_phys_get(_ g: inout Generic<UnicodeScalar>, x: Int) -> Int {
  return g.mono_phys
  // CHECK: struct_element_addr %{{.*}}, #Generic.mono_phys
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties26bound_generic_mono_log_get{{[_0-9a-zA-Z]*}}F
func bound_generic_mono_log_get(_ g: Generic<UnicodeScalar>, x: Int) -> Int {
  return g.mono_log
// CHECK: [[GENERIC_GET_METHOD:%[0-9]+]] = function_ref @$s10properties7GenericV8mono_log{{[_0-9a-zA-Z]*}}vg
  // CHECK: apply [[GENERIC_GET_METHOD]]<
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties22generic_subscript_type{{[_0-9a-zA-Z]*}}F
func generic_subscript_type<T>(_ g: Generic<T>, i: T, x: T) -> T {
  var g = g
  g[i] = x
  return g[i]
}

/*TODO: archetype and existential properties and subscripts */

struct StaticProperty {
  static var foo: Int {
    get {
      return zero
    }
    set {}
  }
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties10static_get{{[_0-9a-zA-Z]*}}F
// CHECK:   function_ref @$s10properties14StaticPropertyV3foo{{[_0-9a-zA-Z]*}}vgZ : $@convention(method) (@thin StaticProperty.Type) -> Int
func static_get() -> Int {
  return StaticProperty.foo
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties10static_set{{[_0-9a-zA-Z]*}}F
// CHECK:   function_ref @$s10properties14StaticPropertyV3foo{{[_0-9a-zA-Z]*}}vsZ : $@convention(method) (Int, @thin StaticProperty.Type) -> ()
func static_set(_ x: Int) {
  StaticProperty.foo = x
}

func takeInt(_ a : Int) {}

protocol ForceAccessors {
  var a: Int { get set }
}

struct DidSetWillSetTests: ForceAccessors {
  // CHECK-LABEL: sil hidden [ossa] @$s10properties010DidSetWillC5TestsV{{[_0-9a-zA-Z]*}}fC
  init(x : Int) {
    // Accesses to didset/willset variables are direct in init methods and dtors.
    a = x
    a = x

    // CHECK: bb0(%0 : $Int, %1 : $@thin DidSetWillSetTests.Type):
    // CHECK:        [[SELF:%.*]] = mark_uninitialized [rootself]
    // CHECK:        [[PB_SELF:%.*]] = project_box [[SELF]]
    // CHECK:        [[WRITE:%.*]] = begin_access [modify] [unknown] [[PB_SELF]]
    // CHECK:        [[P1:%.*]] = struct_element_addr [[WRITE]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
    // CHECK-NEXT:   assign %0 to [[P1]]
    // CHECK:        [[WRITE:%.*]] = begin_access [modify] [unknown] [[PB_SELF]]
    // CHECK:        [[P2:%.*]] = struct_element_addr [[WRITE]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
    // CHECK-NEXT:   assign %0 to [[P2]]
  }

  var a: Int {
    // CHECK-LABEL: sil private [ossa] @$s10properties010DidSetWillC5TestsV1a{{[_0-9a-zA-Z]*}}vw
    willSet(newA) {
      // CHECK: bb0(%0 : $Int, %1 : $*DidSetWillSetTests):
      // CHECK-NEXT: debug_value %0
      // CHECK-NEXT: debug_value_addr %1 : $*DidSetWillSetTests

      takeInt(a)

      // CHECK: [[READ:%.*]] = begin_access [read] [unknown] %1
      // CHECK-NEXT: [[FIELDPTR:%.*]] = struct_element_addr [[READ]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
      // CHECK-NEXT: [[A:%.*]] = load [trivial] [[FIELDPTR]] : $*Int
      // CHECK-NEXT: end_access [[READ]]
      // CHECK: [[TAKEINTFN:%.*]] = function_ref @$s10properties7takeInt{{[_0-9a-zA-Z]*}}F
      // CHECK-NEXT: apply [[TAKEINTFN]]([[A]]) : $@convention(thin) (Int) -> ()

      takeInt(newA)

      // CHECK-NEXT: // function_ref properties.takeInt(Swift.Int) -> ()
      // CHECK-NEXT: [[TAKEINTFN:%.*]] = function_ref @$s10properties7takeInt{{[_0-9a-zA-Z]*}}F
      // CHECK-NEXT: apply [[TAKEINTFN]](%0) : $@convention(thin) (Int) -> ()

      a = zero  // reassign, but don't infinite loop.

      // CHECK-NEXT: // function_ref properties.zero.unsafeMutableAddressor : Swift.Int
      // CHECK-NEXT: [[ZEROFN:%.*]] = function_ref @$s10properties4zero{{[_0-9a-zA-Z]*}}vau
      // CHECK-NEXT: [[ZERORAW:%.*]] = apply [[ZEROFN]]() : $@convention(thin) () -> Builtin.RawPointer
      // CHECK-NEXT: [[ZEROADDR:%.*]] = pointer_to_address [[ZERORAW]] : $Builtin.RawPointer to [strict] $*Int
      // CHECK-NEXT: [[READ:%.*]] = begin_access [read] [dynamic] [[ZEROADDR]] : $*Int
      // CHECK-NEXT: [[ZERO:%.*]] = load [trivial] [[READ]]
      // CHECK-NEXT: end_access [[READ]] : $*Int
      // CHECK-NEXT: [[WRITE:%.*]] = begin_access [modify] [unknown] %1
      // CHECK-NEXT: [[AADDR:%.*]] = struct_element_addr [[WRITE]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
      // CHECK-NEXT: assign [[ZERO]] to [[AADDR]]
    }

    // CHECK-LABEL: sil private [ossa] @$s10properties010DidSetWillC5TestsV1a{{[_0-9a-zA-Z]*}}vW
    didSet {
      // CHECK: bb0(%0 : $Int, %1 : $*DidSetWillSetTests):
      // CHECK-NEXT: debug
      // CHECK-NEXT: debug_value_addr %1 : $*DidSetWillSetTests

      takeInt(a)

      // CHECK: [[READ:%.*]] = begin_access [read] [unknown] %1
      // CHECK-NEXT: [[AADDR:%.*]] = struct_element_addr [[READ]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
      // CHECK-NEXT: [[A:%.*]] = load [trivial] [[AADDR]] : $*Int
      // CHECK-NEXT: end_access [[READ]]
      // CHECK-NEXT: // function_ref properties.takeInt(Swift.Int) -> ()
      // CHECK-NEXT: [[TAKEINTFN:%.*]] = function_ref @$s10properties7takeInt{{[_0-9a-zA-Z]*}}F
      // CHECK-NEXT: apply [[TAKEINTFN]]([[A]]) : $@convention(thin) (Int) -> ()

      (self).a = zero  // reassign, but don't infinite loop.

      // CHECK-NEXT: // function_ref properties.zero.unsafeMutableAddressor : Swift.Int
      // CHECK-NEXT: [[ZEROFN:%.*]] = function_ref @$s10properties4zero{{[_0-9a-zA-Z]*}}vau
      // CHECK-NEXT: [[ZERORAW:%.*]] = apply [[ZEROFN]]() : $@convention(thin) () -> Builtin.RawPointer
      // CHECK-NEXT: [[ZEROADDR:%.*]] = pointer_to_address [[ZERORAW]] : $Builtin.RawPointer to [strict] $*Int
      // CHECK-NEXT: [[READ:%.*]] = begin_access [read] [dynamic] [[ZEROADDR]] : $*Int
      // CHECK-NEXT: [[ZERO:%.*]] = load [trivial] [[READ]]
      // CHECK-NEXT: end_access [[READ]] : $*Int
      // CHECK-NEXT: [[WRITE:%.*]] = begin_access [modify] [unknown] %1
      // CHECK-NEXT: [[AADDR:%.*]] = struct_element_addr [[WRITE]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
      // CHECK-NEXT: assign [[ZERO]] to [[AADDR]]
    }
  }

  // This is the synthesized getter and setter for the willset/didset variable.

  // CHECK-LABEL: sil hidden [transparent] [ossa] @$s10properties010DidSetWillC5TestsV1aSivg
  // CHECK: bb0(%0 : $DidSetWillSetTests):
  // CHECK-NEXT:   debug_value %0
  // CHECK-NEXT:   %2 = struct_extract %0 : $DidSetWillSetTests, #DidSetWillSetTests.a
  // CHECK-NEXT:   return %2 : $Int{{.*}}                      // id: %3


  // CHECK-LABEL: sil hidden [ossa] @$s10properties010DidSetWillC5TestsV1aSivs
  // CHECK: bb0(%0 : $Int, %1 : $*DidSetWillSetTests):
  // CHECK-NEXT: debug_value %0
  // CHECK-NEXT: debug_value_addr %1

  // CHECK-NEXT: [[READ:%.*]] = begin_access [read] [unknown] %1
  // CHECK-NEXT: [[AADDR:%.*]] = struct_element_addr [[READ]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
  // CHECK-NEXT: [[OLDVAL:%.*]] = load [trivial] [[AADDR]] : $*Int
  // CHECK-NEXT: end_access [[READ]]
  // CHECK-NEXT: debug_value [[OLDVAL]] : $Int, let, name "tmp"

  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] %1
  // CHECK-NEXT: // function_ref {{.*}}.DidSetWillSetTests.a.willset : Swift.Int
  // CHECK-NEXT: [[WILLSETFN:%.*]] = function_ref @$s10properties010DidSetWillC5TestsV1a{{[_0-9a-zA-Z]*}}vw
  // CHECK-NEXT:  apply [[WILLSETFN]](%0, [[WRITE]]) : $@convention(method) (Int, @inout DidSetWillSetTests) -> ()
  // CHECK-NEXT: end_access [[WRITE]]
  // CHECK-NEXT: [[WRITE:%.*]] = begin_access [modify] [unknown] %1
  // CHECK-NEXT: [[AADDR:%.*]] = struct_element_addr [[WRITE]] : $*DidSetWillSetTests, #DidSetWillSetTests.a
  // CHECK-NEXT: assign %0 to [[AADDR]] : $*Int
  // CHECK-NEXT: end_access [[WRITE]]
  // CHECK-NEXT: [[WRITE:%.*]] = begin_access [modify] [unknown] %1
  // CHECK-NEXT: // function_ref {{.*}}.DidSetWillSetTests.a.didset : Swift.Int
  // CHECK-NEXT: [[DIDSETFN:%.*]] = function_ref @$s10properties010DidSetWillC5TestsV1a{{[_0-9a-zA-Z]*}}vW : $@convention(method) (Int, @inout DidSetWillSetTests) -> ()
  // CHECK-NEXT: apply [[DIDSETFN]]([[OLDVAL]], [[WRITE]]) : $@convention(method) (Int, @inout DidSetWillSetTests) -> ()

  // CHECK-LABEL: sil hidden [ossa] @$s10properties010DidSetWillC5TestsV8testReadSiyF
  // CHECK:         [[SELF:%.*]] = begin_access [read] [unknown] %0 : $*DidSetWillSetTests
  // CHECK-NEXT:    [[PROP:%.*]] = struct_element_addr [[SELF]] : $*DidSetWillSetTests
  // CHECK-NEXT:    [[LOAD:%.*]] = load [trivial] [[PROP]] : $*Int
  // CHECK-NEXT:    end_access [[SELF]] : $*DidSetWillSetTests
  // CHECK-NEXT:    return [[LOAD]] : $Int
  mutating func testRead() -> Int {
    return a
  }

  // CHECK-LABEL: sil hidden [ossa] @$s10properties010DidSetWillC5TestsV9testWrite5inputySi_tF
  // CHECK:         [[SELF:%.*]] = begin_access [modify] [unknown] %1 : $*DidSetWillSetTests
  // CHECK-NEXT:    // function_ref properties.DidSetWillSetTests.a.setter
  // CHECK-NEXT:    [[SETTER:%.*]] = function_ref @$s10properties010DidSetWillC5TestsV1aSivs
  // CHECK-NEXT:    apply [[SETTER]](%0, [[SELF]])
  // CHECK-NEXT:    end_access [[SELF]] : $*DidSetWillSetTests
  // CHECK-NEXT:    [[RET:%.*]] = tuple ()
  // CHECK-NEXT:    return [[RET]] : $()
  mutating func testWrite(input: Int) {
    a = input
  }

  // CHECK-LABEL: sil hidden [ossa] @$s10properties010DidSetWillC5TestsV13testReadWrite5inputySi_tF
  // CHECK:         [[SELF:%.*]] = begin_access [modify] [unknown] %1 : $*DidSetWillSetTests
  // CHECK-NEXT:    [[TEMP:%.*]] = alloc_stack $Int
  // CHECK-NEXT:    [[PROP:%.*]] = struct_element_addr [[SELF]] : $*DidSetWillSetTests
  // CHECK-NEXT:    [[LOAD:%.*]] = load [trivial] [[PROP]] : $*Int
  // CHECK-NEXT:    store [[LOAD]] to [trivial] [[TEMP]] : $*Int
  // (modification goes here)
  // CHECK:         [[RELOAD:%.*]] = load [trivial] [[TEMP]] : $*Int
  // CHECK-NEXT:    // function_ref properties.DidSetWillSetTests.a.setter
  // CHECK-NEXT:    [[SETTER:%.*]] = function_ref @$s10properties010DidSetWillC5TestsV1aSivs
  // CHECK-NEXT:    apply [[SETTER]]([[RELOAD]], [[SELF]])
  // CHECK-NEXT:    end_access [[SELF]] : $*DidSetWillSetTests
  // CHECK-NEXT:    dealloc_stack [[TEMP]] : $*Int
  // CHECK-NEXT:    [[RET:%.*]] = tuple ()
  // CHECK-NEXT:    return [[RET]] : $()
  mutating func testReadWrite(input: Int) {
    a += input
  }
}


// Test global observing properties.

var global_observing_property : Int = zero {
  // The variable is initialized with "zero".
  // CHECK-LABEL: sil private [ossa] @globalinit_{{.*}}_func1 : $@convention(c) () -> () {
  // CHECK: bb0:
  // CHECK-NEXT: alloc_global @$s10properties25global_observing_propertySiv
  // CHECK-NEXT: %1 = global_addr @$s10properties25global_observing_propertySivp : $*Int
  // CHECK: properties.zero.unsafeMutableAddressor
  // CHECK: return

  // global_observing_property's setter needs to call didSet.

  // CHECK-LABEL: sil private [ossa] @$s10properties25global_observing_property{{[_0-9a-zA-Z]*}}vW
  didSet {
    // The didSet implementation needs to call takeInt.
    takeInt(global_observing_property)

    // CHECK: function_ref properties.takeInt
    // CHECK-NEXT: function_ref @$s10properties7takeInt{{[_0-9a-zA-Z]*}}F

    // Setting the variable from within its own didSet doesn't recursively call didSet.
    global_observing_property = zero

    // CHECK: // function_ref properties.global_observing_property.unsafeMutableAddressor : Swift.Int
    // CHECK-NEXT: [[ADDRESSOR:%.*]] = function_ref @$s10properties25global_observing_propertySivau : $@convention(thin) () -> Builtin.RawPointer
    // CHECK-NEXT: [[ADDRESS:%.*]] = apply [[ADDRESSOR]]() : $@convention(thin) () -> Builtin.RawPointer
    // CHECK-NEXT: [[POINTER:%.*]] = pointer_to_address [[ADDRESS]] : $Builtin.RawPointer to [strict] $*Int
    // CHECK-NEXT: // function_ref properties.zero.unsafeMutableAddressor : Swift.Int
    // CHECK-NEXT: [[ZEROFN:%.*]] = function_ref @$s10properties4zero{{[_0-9a-zA-Z]*}}vau
    // CHECK-NEXT: [[ZERORAW:%.*]] = apply [[ZEROFN]]() : $@convention(thin) () -> Builtin.RawPointer
    // CHECK-NEXT: [[ZEROADDR:%.*]] = pointer_to_address [[ZERORAW]] : $Builtin.RawPointer to [strict] $*Int
    // CHECK-NEXT: [[READ:%.*]] = begin_access [read] [dynamic] [[ZEROADDR]] : $*Int
    // CHECK-NEXT: [[ZERO:%.*]] = load [trivial] [[READ]]
    // CHECK-NEXT: end_access [[READ]] : $*Int
    // CHECK-NEXT: [[WRITE:%.*]] = begin_access [modify] [dynamic] [[POINTER]] : $*Int
    // CHECK-NEXT: assign [[ZERO]] to [[WRITE]] : $*Int
    // CHECK-NEXT: end_access [[WRITE]] : $*Int
    // CHECK-NOT: function_ref @$s10properties25global_observing_property{{[_0-9a-zA-Z]*}}vW
    // CHECK: end sil function
  }
  // CHECK-LABEL: sil hidden [ossa] @$s10properties25global_observing_property{{[_0-9a-zA-Z]*}}vs
  // CHECK: function_ref properties.global_observing_property.unsafeMutableAddressor
  // CHECK-NEXT:  function_ref @$s10properties25global_observing_property{{[_0-9a-zA-Z]*}}vau
  // CHECK: function_ref properties.global_observing_property.didset
  // CHECK-NEXT: function_ref @$s10properties25global_observing_property{{[_0-9a-zA-Z]*}}vW

}

func force_global_observing_property_setter() {
  let x = global_observing_property
  global_observing_property = x
}

// Test local observing properties.

// CHECK-LABEL: sil hidden [ossa] @$s10properties24local_observing_property{{[_0-9a-zA-Z]*}}SiF
func local_observing_property(_ arg: Int) {
  var localproperty: Int = arg {
    didSet {
      takeInt(localproperty)
      localproperty = zero
    }
  }

  takeInt(localproperty)
  localproperty = arg

  // Alloc and initialize the property to the argument value.
  // CHECK: bb0([[ARG:%[0-9]+]] : $Int)
  // CHECK: [[BOX:%[0-9]+]] = alloc_box ${ var Int }
  // CHECK: [[PB:%.*]] = project_box [[BOX]]
  // CHECK: store [[ARG]] to [trivial] [[PB]]
}

// didSet of localproperty (above)
// Ensure that setting the variable from within its own didSet doesn't recursively call didSet.

// CHECK-LABEL: sil private [ossa] @$s10properties24local_observing_property{{[_0-9a-zA-Z]*}}SiF13localproperty{{[_0-9a-zA-Z]*}}SivW
// CHECK: bb0(%0 : $Int, %1 : @guaranteed ${ var Int })
// CHECK: [[POINTER:%.*]] = project_box %1 : ${ var Int }, 0
// CHECK: // function_ref properties.zero.unsafeMutableAddressor : Swift.Int
// CHECK-NEXT: [[ZEROFN:%.*]] = function_ref @$s10properties4zero{{[_0-9a-zA-Z]*}}vau
// CHECK-NEXT: [[ZERORAW:%.*]] = apply [[ZEROFN]]() : $@convention(thin) () -> Builtin.RawPointer
// CHECK-NEXT: [[ZEROADDR:%.*]] = pointer_to_address [[ZERORAW]] : $Builtin.RawPointer to [strict] $*Int
// CHECK-NEXT: [[READ:%.*]] = begin_access [read] [dynamic] [[ZEROADDR]] : $*Int
// CHECK-NEXT: [[ZERO:%.*]] = load [trivial] [[READ]]
// CHECK-NEXT: end_access [[READ]] : $*Int

// CHECK-NEXT: [[WRITE:%.*]] = begin_access [modify] [unknown] [[POINTER]] : $*Int
// CHECK-NEXT: assign [[ZERO]] to [[WRITE]] : $*Int
// CHECK-NEXT: end_access [[WRITE]] : $*Int
// CHECK-NOT: function_ref @$s10properties24local_observing_property{{[_0-9a-zA-Z]*}}SiF13localproperty{{[_0-9a-zA-Z]*}}SivW
// CHECK: end sil function

func local_generic_observing_property<T>(_ arg: Int, _: T) {
  var localproperty1: Int = arg {
    didSet {
      takeInt(localproperty1)
    }
  }
  
  takeInt(localproperty1)
  localproperty1 = arg

  var localproperty2: Int = arg {
    didSet {
      _ = T.self
      takeInt(localproperty2)
    }
  }
  
  takeInt(localproperty2)
  localproperty2 = arg
}


// <rdar://problem/16006333> observing properties don't work in @objc classes
@objc
class ObservingPropertyInObjCClass {
  var bounds: Int {
    willSet {}
    didSet {}
  }

  init(b: Int) { bounds = b }
}



// Superclass init methods should not get direct access to be class properties.
// rdar://16151899

class rdar16151899Base {
  var x: Int = zero {
  willSet {
    use(x)
  }
  }
}

class rdar16151899Derived : rdar16151899Base {
    // CHECK-LABEL: sil hidden [ossa] @$s10properties19rdar16151899DerivedC{{[_0-9a-zA-Z]*}}fc
    override init() {
        super.init()
        // CHECK: upcast {{.*}} : $rdar16151899Derived to $rdar16151899Base
        // CHECK: function_ref @$s10properties16rdar16151899BaseCACycfc : $@convention(method) (@owned rdar16151899Base) -> @owned rdar16151899Base

        // This should not be a direct access, it should call the setter in the
        // base.
        x = zero
        
        // CHECK:  [[BASEPTR:%[0-9]+]] = upcast {{.*}} : $rdar16151899Derived to $rdar16151899Base
        // CHECK: load{{.*}}Int
        // CHECK-NEXT: end_access {{.*}} : $*Int
        // CHECK-NEXT: [[SETTER:%[0-9]+]] = class_method {{.*}} : $rdar16151899Base, #rdar16151899Base.x!setter.1 : (rdar16151899Base)
        // CHECK-NEXT: apply [[SETTER]]({{.*}}, [[BASEPTR]]) 
    }
}


func propertyWithDidSetTakingOldValue() {
  var p : Int = zero {
    didSet(oldValue) {
      // access to oldValue
      use(oldValue)
      // and newValue.
      use(p)
    }
  }

  p = zero
}

// CHECK: // setter of p #1 : Swift.Int in properties.propertyWithDidSetTakingOldValue()
// CHECK-NEXT: sil {{.*}} [ossa] @$s10properties32propertyWithDidSetTakingOldValueyyF1pL_Sivs
// CHECK: bb0([[ARG1:%.*]] : $Int, [[ARG2:%.*]] : @guaranteed ${ var Int }):
// CHECK-NEXT:  debug_value [[ARG1]] : $Int, let, name "newValue", argno 1
// CHECK-NEXT:  [[ARG2_PB:%.*]] = project_box [[ARG2]]
// CHECK-NEXT:  debug_value_addr [[ARG2_PB]] : $*Int, var, name "p", argno 2
// CHECK-NEXT:  [[READ:%.*]] = begin_access [read] [unknown] [[ARG2_PB]]
// CHECK-NEXT:  [[ARG2_PB_VAL:%.*]] = load [trivial] [[READ]] : $*Int
// CHECK-NEXT:  end_access [[READ]]
// CHECK-NEXT:  debug_value [[ARG2_PB_VAL]] : $Int
// CHECK-NEXT:  [[WRITE:%.*]] = begin_access [modify] [unknown] [[ARG2_PB]]
// CHECK-NEXT:  assign [[ARG1]] to [[WRITE]] : $*Int
// CHECK-NEXT:  end_access [[WRITE]]
// SEMANTIC ARC TODO: Another case where we need to put the mark_function_escape on a new projection after a copy.
// CHECK-NEXT:  mark_function_escape [[ARG2_PB]]
// CHECK-NEXT:  // function_ref
// CHECK-NEXT:  [[FUNC:%.*]] = function_ref @$s10properties32propertyWithDidSetTakingOldValueyyF1pL_SivW : $@convention(thin) (Int, @guaranteed { var Int }) -> ()
// CHECK-NEXT:  %{{.*}} = apply [[FUNC]]([[ARG2_PB_VAL]], [[ARG2]]) : $@convention(thin) (Int, @guaranteed { var Int }) -> ()
// CHECK-NEXT:  %{{.*}} = tuple ()
// CHECK-NEXT:  return %{{.*}} : $()
// CHECK-NEXT:} // end sil function '$s10properties32propertyWithDidSetTakingOldValue{{[_0-9a-zA-Z]*}}'


class BaseProperty {
  var x : Int { get {} set {} }
}

class DerivedProperty : BaseProperty {
  override var x : Int { get {} set {} }

  func super_property_reference() -> Int {
    return super.x
  }
}

// rdar://16381392 - Super property references in non-objc classes should be direct.

// CHECK-LABEL: sil hidden [ossa] @$s10properties15DerivedPropertyC24super_property_referenceSiyF : $@convention(method) (@guaranteed DerivedProperty) -> Int {
// CHECK: bb0([[SELF:%.*]] : @guaranteed $DerivedProperty):
// CHECK:   [[SELF_COPY:%[0-9]+]] = copy_value [[SELF]]
// CHECK:   [[BASEPTR:%[0-9]+]] = upcast [[SELF_COPY]] : $DerivedProperty to $BaseProperty
// CHECK:   [[BORROW:%[0-9]+]] = begin_borrow [[BASEPTR]]
// CHECK:   [[FN:%[0-9]+]] = function_ref @$s10properties12BasePropertyC1xSivg : $@convention(method) (@guaranteed BaseProperty) -> Int 
// CHECK:   [[RESULT:%.*]] = apply [[FN]]([[BORROW]]) : $@convention(method) (@guaranteed BaseProperty) -> Int
// CHECK:   destroy_value [[BASEPTR]]
// CHECK:   return [[RESULT]] : $Int
// CHECK: } // end sil function '$s10properties15DerivedPropertyC24super_property_referenceSiyF'


// <rdar://problem/16411449> ownership qualifiers don't work with non-mutating struct property
struct ReferenceStorageTypeRValues {
  unowned var p1 : Ref

  func testRValueUnowned() -> Ref {
    return p1
  }
// CHECK: sil hidden [ossa] @{{.*}}testRValueUnowned{{.*}} : $@convention(method) (@guaranteed ReferenceStorageTypeRValues) -> @owned Ref {
// CHECK: bb0([[ARG:%.*]] : @guaranteed $ReferenceStorageTypeRValues):
// CHECK-NEXT:   debug_value [[ARG]] : $ReferenceStorageTypeRValues
// CHECK-NEXT:   [[UNOWNED_ARG_FIELD:%.*]] = struct_extract [[ARG]] : $ReferenceStorageTypeRValues, #ReferenceStorageTypeRValues.p1
// CHECK-NEXT:   [[COPIED_VALUE:%.*]] = copy_unowned_value [[UNOWNED_ARG_FIELD]]
// CHECK-NEXT:   return [[COPIED_VALUE]] : $Ref

  init() {
  }
}


// <rdar://problem/16406886> Observing properties don't work with ownership types
struct ObservingPropertiesWithOwnershipTypes {
  unowned var alwaysPresent : Ref {
    didSet {
    }
  }

  init(res: Ref) {
    alwaysPresent = res
  }
}

struct ObservingPropertiesWithOwnershipTypesInferred {
  unowned var alwaysPresent = Ref(i: 0) {
    didSet {
    }
  }

  weak var maybePresent = nil as Ref? {
    willSet {
    }
  }
}

// <rdar://problem/16554876> property accessor synthesization of weak variables doesn't work
protocol WeakPropertyProtocol {
 var maybePresent : Ref? { get set }
}

struct WeakPropertyStruct : WeakPropertyProtocol {
 weak var maybePresent : Ref?

  init() {
    maybePresent = nil
  }
}

// <rdar://problem/16629598> direct property accesses to generic struct
// properties were being mischecked as computed property accesses.

struct SomeGenericStruct<T> {
  var x: Int
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties4getX{{[_0-9a-zA-Z]*}}F
// CHECK:         struct_extract {{%.*}} : $SomeGenericStruct<T>, #SomeGenericStruct.x
func getX<T>(_ g: SomeGenericStruct<T>) -> Int {
  return g.x
}


//<rdar://problem/16620121> Initializing constructor tries to initialize computed property overridden with willSet/didSet
class ObservedBase {
     var printInfo: Ref!
}
class ObservedDerived : ObservedBase {
  override init() {}
  override var printInfo: Ref! {
    didSet { }
  }
}



/// <rdar://problem/16953517> Class properties should be allowed in protocols, even without stored class properties
protocol ProtoWithClassProp {
  static var x: Int { get }
}

class ClassWithClassProp : ProtoWithClassProp {
  class var x: Int {
  return 42
  }
}

struct StructWithClassProp : ProtoWithClassProp {
  static var x: Int {
  return 19
  }
}


func getX<T : ProtoWithClassProp>(_ a : T) -> Int {
  return T.x
}

func testClassPropertiesInProtocol() -> Int {
  return getX(ClassWithClassProp())+getX(StructWithClassProp())
}

class GenericClass<T> {
  var x: T
  var y: Int
  final let z: T

  init() { fatalError("scaffold") }
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties12genericPropsyyAA12GenericClassCySSGF : $@convention(thin) (@guaranteed GenericClass<String>) -> () {
func genericProps(_ x: GenericClass<String>) {
  // CHECK: bb0([[ARG:%.*]] : @guaranteed $GenericClass<String>):
  // CHECK:   class_method [[ARG]] : $GenericClass<String>, #GenericClass.x!getter.1
  // CHECK:   apply {{.*}}<String>({{.*}}, [[ARG]]) : $@convention(method) <τ_0_0> (@guaranteed GenericClass<τ_0_0>) -> @out τ_0_0
  let _ = x.x
  // CHECK:   class_method [[ARG]] : $GenericClass<String>, #GenericClass.y!getter.1
  // CHECK:   apply {{.*}}<String>([[ARG]]) : $@convention(method) <τ_0_0> (@guaranteed GenericClass<τ_0_0>) -> Int
  let _ = x.y
  // CHECK:   [[Z:%.*]] = ref_element_addr [[ARG]] : $GenericClass<String>, #GenericClass.z
  // CHECK:   [[LOADED_Z:%.*]] = load [copy] [[Z]] : $*String
  // CHECK:   destroy_value [[LOADED_Z]]
  // CHECK-NOT:   destroy_value [[ARG]]
  let _ = x.z
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties28genericPropsInGenericContext{{[_0-9a-zA-Z]*}}F
func genericPropsInGenericContext<U>(_ x: GenericClass<U>) {
  // CHECK: bb0([[ARG:%.*]] : @guaranteed $GenericClass<U>):
  // CHECK:   [[Z:%.*]] = ref_element_addr [[ARG]] : $GenericClass<U>, #GenericClass.z
  // CHECK:   copy_addr [[Z]] {{.*}} : $*U
  let _ = x.z
}


// <rdar://problem/18275556> 'let' properties in a class should be implicitly final
class ClassWithLetProperty {
  let p = 42
  @objc dynamic let q = 97

  // We shouldn't have any dynamic dispatch within this method, just load p.
  func ReturnConstant() -> Int { return p }
// CHECK-LABEL: sil hidden [ossa] @$s10properties20ClassWithLetPropertyC14ReturnConstant{{[_0-9a-zA-Z]*}}F
// CHECK:       bb0([[ARG:%.*]] : @guaranteed $ClassWithLetProperty):
// CHECK-NEXT:    debug_value
// CHECK-NEXT:    [[PTR:%[0-9]+]] = ref_element_addr [[ARG]] : $ClassWithLetProperty, #ClassWithLetProperty.p
// CHECK-NEXT:    [[VAL:%[0-9]+]] = load [trivial] [[PTR]] : $*Int
// CHECK-NEXT:   return [[VAL]] : $Int


  // This property is marked dynamic, so go through the getter, always.
  func ReturnDynamicConstant() -> Int { return q }
// CHECK-LABEL: sil hidden [ossa] @$s10properties20ClassWithLetPropertyC21ReturnDynamicConstant{{[_0-9a-zA-Z]*}}F
// CHECK: objc_method %0 : $ClassWithLetProperty, #ClassWithLetProperty.q!getter.1.foreign
}


// <rdar://problem/19254812> DI bug when referencing let member of a class
class r19254812Base {}
class r19254812Derived: r19254812Base{
  let pi = 3.14159265359
  
  init(x : ()) {
    use(pi)
  }
  
// Accessing the "pi" property should not copy_value/release self.
// CHECK-LABEL: sil hidden [ossa] @$s10properties16r19254812DerivedC{{[_0-9a-zA-Z]*}}fc
// CHECK: [[MARKED_SELF_BOX:%.*]] = mark_uninitialized [derivedself]
// CHECK: [[PB_BOX:%.*]] = project_box [[MARKED_SELF_BOX]]

// Initialization of the pi field: no copy_values/releases.
// CHECK:  [[SELF:%[0-9]+]] = load_borrow [[PB_BOX]] : $*r19254812Derived
// CHECK-NEXT:  [[PIPTR:%[0-9]+]] = ref_element_addr [[SELF]] : $r19254812Derived, #r19254812Derived.pi
// CHECK-NEXT:  assign {{.*}} to [[PIPTR]] : $*Double

// CHECK-NOT: destroy_value
// CHECK-NOT: copy_value

// Load of the pi field: no copy_values/releases.
// CHECK:  [[SELF:%[0-9]+]] = load_borrow [[PB_BOX]] : $*r19254812Derived
// CHECK-NEXT:  [[PIPTR:%[0-9]+]] = ref_element_addr [[SELF]] : $r19254812Derived, #r19254812Derived.pi
// CHECK-NEXT:  {{.*}} = load [trivial] [[PIPTR]] : $*Double
// CHECK: return
}


class RedundantSelfRetains {
  final var f : RedundantSelfRetains
  
  init() {
    f = RedundantSelfRetains()
  }
  
  // <rdar://problem/19275047> Extraneous copy_values/releases of self are bad
  func testMethod1() {
    f = RedundantSelfRetains()
  }
  // CHECK-LABEL: sil hidden [ossa] @$s10properties20RedundantSelfRetainsC11testMethod1{{[_0-9a-zA-Z]*}}F
  // CHECK: bb0(%0 : @guaranteed $RedundantSelfRetains):

  // CHECK-NOT: copy_value
  
  // CHECK: [[FPTR:%[0-9]+]] = ref_element_addr %0 : $RedundantSelfRetains, #RedundantSelfRetains.f
  // CHECK-NEXT: [[WRITE:%.*]] = begin_access [modify] [dynamic] [[FPTR]] : $*RedundantSelfRetains
  // CHECK-NEXT: assign {{.*}} to [[WRITE]] : $*RedundantSelfRetains

  // CHECK: return
}

class RedundantRetains {
  final var field = 0
}

func testRedundantRetains() {
  let a = RedundantRetains()
  a.field = 4  // no copy_value/release of a necessary here.
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties20testRedundantRetainsyyF : $@convention(thin) () -> () {
// CHECK: [[A:%[0-9]+]] = apply
// CHECK-NOT: copy_value
// CHECK: destroy_value [[A]] : $RedundantRetains
// CHECK-NOT: copy_value
// CHECK-NOT: destroy_value
// CHECK: return

struct AddressOnlyNonmutatingSet<T> {
  var x: T
  init(x: T) { self.x = x }
  var prop: Int {
    get { return 0 }
    nonmutating set { }
  }
}

func addressOnlyNonmutatingProperty<T>(_ x: AddressOnlyNonmutatingSet<T>)
-> Int {
  x.prop = 0
  return x.prop
}
// CHECK-LABEL: sil hidden [ossa] @$s10properties30addressOnlyNonmutatingProperty{{[_0-9a-zA-Z]*}}F
// CHECK:         [[SET:%.*]] = function_ref @$s10properties25AddressOnlyNonmutatingSetV4propSivs
// CHECK:         apply [[SET]]<T>({{%.*}}, [[TMP:%[0-9]*]])
// CHECK:         destroy_addr [[TMP]]
// CHECK:         dealloc_stack [[TMP]]
// CHECK:         [[GET:%.*]] = function_ref @$s10properties25AddressOnlyNonmutatingSetV4propSivg
// CHECK:         apply [[GET]]<T>([[TMP:%[0-9]*]])
// CHECK:         destroy_addr [[TMP]]
// CHECK:         dealloc_stack [[TMP]]

protocol MakeAddressOnly {}
struct AddressOnlyReadOnlySubscript {
  var x: MakeAddressOnly?

  subscript(z: Int) -> Int { return z }
}

// CHECK-LABEL: sil hidden [ossa] @$s10properties015addressOnlyReadC24SubscriptFromMutableBase
// CHECK:         [[BASE:%.*]] = alloc_box ${ var AddressOnlyReadOnlySubscript }
// CHECK:         copy_addr [[BASE:%.*]] to [initialization] [[COPY:%.*]] :
// CHECK:         copy_addr [[COPY:%.*]] to [initialization] [[COPY2:%.*]] :
// CHECK:         [[GETTER:%.*]] = function_ref @$s10properties015AddressOnlyReadC9SubscriptV{{[_0-9a-zA-Z]*}}ig
// CHECK:         apply [[GETTER]]({{%.*}}, [[COPY2]])
func addressOnlyReadOnlySubscriptFromMutableBase(_ x: Int) {
  var base = AddressOnlyReadOnlySubscript()
  _ = base[x]
}



/// <rdar://problem/20912019> passing unmaterialized r-value as inout argument
struct MutatingGetterStruct {
  var write: Int {
    mutating get {  }
  }

  // CHECK-LABEL: sil hidden [ossa] @$s10properties20MutatingGetterStructV4test
  // CHECK: [[X:%.*]] = alloc_box ${ var MutatingGetterStruct }, var, name "x"
  // CHECK-NEXT: [[PB:%.*]] = project_box [[X]]
  // CHECK: store {{.*}} to [trivial] [[PB]] : $*MutatingGetterStruct
  // CHECK: [[WRITE:%.*]] = begin_access [modify] [unknown] [[PB]]
  // CHECK: apply {{%.*}}([[WRITE]]) : $@convention(method) (@inout MutatingGetterStruct) -> Int
  static func test() {
    var x = MutatingGetterStruct()
    _ = x.write
  }
}


protocol ProtocolWithReadWriteSubscript {
  subscript(i: Int) -> Int { get set }
}

struct CrashWithUnnamedSubscript : ProtocolWithReadWriteSubscript {
  subscript(_: Int) -> Int { get { } set { } }
}


/// <rdar://problem/26408353> crash when overriding internal property with
/// public property

public class BaseClassWithInternalProperty {
  var x: () = ()
}

public class DerivedClassWithPublicProperty : BaseClassWithInternalProperty {
  public override var x: () {
    didSet {}
  }
}

// CHECK-LABEL: sil hidden [transparent] [ossa] @$s10properties29BaseClassWithInternalPropertyC1xytvg

// CHECK-LABEL: sil [transparent] [serialized] [ossa] @$s10properties30DerivedClassWithPublicPropertyC1xytvg
// CHECK:       bb0([[SELF:%.*]] : @guaranteed $DerivedClassWithPublicProperty):
// CHECK:         [[SELF_COPY:%.*]] = copy_value [[SELF]] : $DerivedClassWithPublicProperty
// CHECK-NEXT:    [[SUPER:%.*]] = upcast [[SELF_COPY]] : $DerivedClassWithPublicProperty to $BaseClassWithInternalProperty
// CHECK-NEXT:    [[BORROWED_SUPER:%.*]] = begin_borrow [[SUPER]]
// CHECK-NEXT:    [[DOWNCAST_BORROWED_SUPER:%.*]] = unchecked_ref_cast [[BORROWED_SUPER]] : $BaseClassWithInternalProperty to $DerivedClassWithPublicProperty
// CHECK-NEXT:    [[METHOD:%.*]] = super_method [[DOWNCAST_BORROWED_SUPER]] : $DerivedClassWithPublicProperty, #BaseClassWithInternalProperty.x!getter.1 : (BaseClassWithInternalProperty) -> () -> (), $@convention(method) (@guaranteed BaseClassWithInternalProperty) -> ()
// CHECK-NEXT:    [[RESULT:%.*]] = apply [[METHOD]]([[BORROWED_SUPER]]) : $@convention(method) (@guaranteed BaseClassWithInternalProperty) -> ()
// CHECK-NEXT:    end_borrow [[BORROWED_SUPER]]
// CHECK-NEXT:    destroy_value [[SUPER]] : $BaseClassWithInternalProperty
// CHECK: } // end sil function '$s10properties30DerivedClassWithPublicPropertyC1xytvg'

// Make sure that we can handle this AST:
// (load_expr
//   (open_existential_expr
//     (opaque_expr A)
//     ...
//     (load_expr
//        (opaque_expr  ))))

class ReferenceType {
  var p: NonmutatingProtocol
  init(p: NonmutatingProtocol) { self.p = p }
}

protocol NonmutatingProtocol {
  var x: Int { get nonmutating set }
}

// sil hidden [ossa] @$s10properties19overlappingLoadExpr1cyAA13ReferenceTypeCz_tF : $@convention(thin) (@inout ReferenceType) -> () {
// CHECK:        [[C_INOUT:%.*]] = begin_access [read] [unknown] %0 : $*ReferenceType
// CHECK-NEXT:   [[C:%.*]] = load [copy] [[C_INOUT:%.*]] : $*ReferenceType
// CHECK-NEXT:   end_access [[C_INOUT]] : $*ReferenceType
// CHECK-NEXT:   [[C_BORROW:%.*]] = begin_borrow [[C]]
// CHECK-NEXT:   [[C_FIELD_BOX:%.*]] = alloc_stack $NonmutatingProtocol
// CHECK-NEXT:   [[GETTER:%.*]] = class_method [[C_BORROW]] : $ReferenceType, #ReferenceType.p!getter.1 : (ReferenceType) -> () -> NonmutatingProtocol, $@convention(method) (@guaranteed ReferenceType) -> @out NonmutatingProtocol
// CHECK-NEXT:   apply [[GETTER]]([[C_FIELD_BOX]], [[C_BORROW]]) : $@convention(method) (@guaranteed ReferenceType) -> @out NonmutatingProtocol
// CHECK-NEXT:   end_borrow [[C_BORROW]]

// CHECK-NEXT:   [[C_FIELD_PAYLOAD:%.*]] = open_existential_addr immutable_access [[C_FIELD_BOX]] : $*NonmutatingProtocol to $*@opened("{{.*}}") NonmutatingProtocol
// CHECK-NEXT:   [[C_FIELD_COPY:%.*]] = alloc_stack $@opened("{{.*}}") NonmutatingProtocol
// CHECK-NEXT:   copy_addr [[C_FIELD_PAYLOAD]] to [initialization] [[C_FIELD_COPY]] : $*@opened("{{.*}}") NonmutatingProtocol
// CHECK-NEXT:   destroy_value [[C]] : $ReferenceType
// CHECK-NEXT:   [[C_FIELD_BORROW:%.*]] = alloc_stack
// CHECK-NEXT:   copy_addr [[C_FIELD_COPY]] to [initialization] [[C_FIELD_BORROW]]
// CHECK-NEXT:   [[GETTER:%.*]] = witness_method $@opened("{{.*}}") NonmutatingProtocol, #NonmutatingProtocol.x!getter.1 : <Self where Self : NonmutatingProtocol> (Self) -> () -> Int, [[C_FIELD_PAYLOAD]] : $*@opened("{{.*}}") NonmutatingProtocol : $@convention(witness_method: NonmutatingProtocol) <τ_0_0 where τ_0_0 : NonmutatingProtocol> (@in_guaranteed τ_0_0) -> Int
// CHECK-NEXT:   [[RESULT_VALUE:%.*]] = apply [[GETTER]]<@opened("{{.*}}") NonmutatingProtocol>([[C_FIELD_BORROW]]) : $@convention(witness_method: NonmutatingProtocol) <τ_0_0 where τ_0_0 : NonmutatingProtocol> (@in_guaranteed τ_0_0) -> Int
// CHECK-NEXT:   destroy_addr [[C_FIELD_BORROW]]
// CHECK-NEXT:   destroy_addr [[C_FIELD_COPY]] : $*@opened("{{.*}}") NonmutatingProtocol
// CHECK-NEXT:   dealloc_stack [[C_FIELD_BORROW]]
// CHECK-NEXT:   dealloc_stack [[C_FIELD_COPY]] : $*@opened("{{.*}}") NonmutatingProtocol
// CHECK-NEXT:   destroy_addr [[C_FIELD_BOX]] : $*NonmutatingProtocol
// CHECK-NEXT:   dealloc_stack [[C_FIELD_BOX]] : $*NonmutatingProtocol
// CHECK-NEXT:   tuple ()
// CHECK-NEXT:   return

func overlappingLoadExpr(c: inout ReferenceType) {
  _ = c.p.x
}

var globalOptionalComputed: Int? {
  didSet { print("hello") }
}

func updateGlobalOptionalComputed() {
  globalOptionalComputed? = 123
}

struct TupleStruct {
  var v: (Int, Int) { get { } set { } }
  var vv: (w: Int, h: Int) { get { } set { } }
}

func assign_to_tuple() {
  var s = TupleStruct()
  s.v = (1, 2)

  let v = (3, 4)
  s.vv = v
}

// CHECK-LABEL: sil private [ossa] @$s10properties8myglobalSivW
// CHECK-LABEL: sil [ossa] @$s10properties8myglobalSivg
// CHECK-LABEL: sil [ossa] @$s10properties8myglobalSivs
public var myglobal : Int = 1 {
  didSet {
    print("myglobal.didSet")
  }
}

// CHECK-LABEL: sil private [ossa] @$s10properties9myglobal2Sivw
// CHECK-LABEL: sil [ossa] @$s10properties9myglobal2Sivg
// CHECK-LABEL: sil [ossa] @$s10properties9myglobal2Sivs
public var myglobal2 : Int = 1 {
  willSet {
    print("myglobal.willSet")
  }
}

// CHECK-LABEL: sil private [ossa] @$s10properties9myglobal3Sivw
// CHECK-LABEL: sil private [ossa] @$s10properties9myglobal3SivW
// CHECK-LABEL: sil [ossa] @$s10properties9myglobal3Sivg
// CHECK-LABEL: sil [ossa] @$s10properties9myglobal3Sivs
public var myglobal3 : Int = 1 {
  willSet {
    print("myglobal.willSet")
  }
  didSet {
    print("myglobal.didSet")
  }
}
