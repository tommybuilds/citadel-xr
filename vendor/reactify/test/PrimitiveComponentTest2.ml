open TestFramework
open TestReconciler
open TestUtility
module TestReact = Reactify.Make (TestReconciler)
open TestReact

let createRootNode () = { children = ref []; nodeId = 0; nodeType = Root }
let a ~testVal children = primitiveComponent ~children (A testVal)
let b children = primitiveComponent ~children B;;

describe "PrimitiveComponent2" (fun { test; _ } ->
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
        validateStructure rootNode expectedStructure))
