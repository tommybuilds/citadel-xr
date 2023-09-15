open TestFramework [@@ocaml.doc " Simple test cases "]

open TestReconciler
open TestUtility
module TestReact = Reactify.Make (TestReconciler)
open TestReact

let createRootNode () = { children = ref []; nodeId = 0; nodeType = Root }
let aComponent ~testVal ~children () = primitiveComponent (A testVal) ~children
let bComponent ~children () = primitiveComponent B ~children
let cComponent ~children () = primitiveComponent C ~children
let a ~testVal children = primitiveComponent (A testVal) ~children
let b children = primitiveComponent B ~children;;

describe "PrimitiveComponent" (fun { test; _ } ->
    test "BasicRenderTest" (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (b []);
        let expectedStructure = TreeNode (Root, [ TreeLeaf B ]) in
        validateStructure rootNode expectedStructure);
    test "BasicRenderTest - multiple updates" (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (b []);
        updateContainer container (b []);
        let expectedStructure = TreeNode (Root, [ TreeLeaf B ]) in
        validateStructure rootNode expectedStructure);
    test "UpdateNodeTest" (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (a ~testVal:1 []);
        let expectedStructure = TreeNode (Root, [ TreeLeaf (A 1) ]) in
        validateStructure rootNode expectedStructure;
        updateContainer container (a ~testVal:2 []);
        let expectedStructure = TreeNode (Root, [ TreeLeaf (A 2) ]) in
        validateStructure rootNode expectedStructure);
    test "UpdateChildNodeTest" (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (a ~testVal:1 [ a ~testVal:2 [] ]);
        let expectedStructure =
          TreeNode (Root, [ TreeNode (A 1, [ TreeLeaf (A 2) ]) ])
        in
        validateStructure rootNode expectedStructure;
        updateContainer container (a ~testVal:1 [ a ~testVal:3 [] ]);
        let expectedStructure =
          TreeNode (Root, [ TreeNode (A 1, [ TreeLeaf (A 3) ]) ])
        in
        validateStructure rootNode expectedStructure);
    test "ReplaceChildNodeTest" (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (a ~testVal:1 [ a ~testVal:2 [] ]);
        let expectedStructure =
          TreeNode (Root, [ TreeNode (A 1, [ TreeLeaf (A 2) ]) ])
        in
        validateStructure rootNode expectedStructure;
        updateContainer container (a ~testVal:1 [ b [] ]);
        let expectedStructure =
          TreeNode (Root, [ TreeNode (A 1, [ TreeLeaf B ]) ])
        in
        validateStructure rootNode expectedStructure);
    test "ReplaceChildrenWithLessChildrenTest" (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (a ~testVal:1 [ b []; b []; b [] ]);
        let expectedStructure =
          TreeNode
            (Root, [ TreeNode (A 1, [ TreeLeaf B; TreeLeaf B; TreeLeaf B ]) ])
        in
        validateStructure rootNode expectedStructure;
        updateContainer container (a ~testVal:1 [ b [] ]);
        let expectedStructure =
          TreeNode (Root, [ TreeNode (A 1, [ TreeLeaf B ]) ])
        in
        validateStructure rootNode expectedStructure);
    test "ReplaceNodeTest" (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (a ~testVal:1 []);
        let expectedStructure = TreeNode (Root, [ TreeLeaf (A 1) ]) in
        validateStructure rootNode expectedStructure;
        updateContainer container (b []);
        let expectedStructure = TreeNode (Root, [ TreeLeaf B ]) in
        validateStructure rootNode expectedStructure);
    test
      ("Regression Test - update, revert does not re-render node"
      [@reason.raw_literal
        "Regression Test - update, revert does not re-render node"]) (fun _ ->
        let rootNode = createRootNode () in
        let container = createContainer rootNode in
        updateContainer container (a ~testVal:0 []);
        updateContainer container (a ~testVal:1 []);
        updateContainer container (a ~testVal:0 []);
        let expectedStructure = TreeNode (Root, [ TreeLeaf (A 0) ]) in
        validateStructure rootNode expectedStructure))
