open Babylon
open EntityManager

module PersistenceKey = struct
  open Js_of_ocaml

  let get_storage () =
    match Js.Optdef.to_option Dom_html.window##.localStorage with
    | exception _ -> raise Not_found
    | None -> raise Not_found
    | Some t -> t

  type 'a persistence = {
    key : string;
    dehydrate : 'a -> string;
    hydrate : string -> 'a;
  }

  type 'a t = 'a persistence option

  let equals key1 key2 =
    match (key1, key2) with
    | None, None -> true
    | Some _, None -> false
    | None, Some _ -> false
    | Some { key = key1; _ }, Some { key = key2; _ } -> String.equal key1 key2

  let none = None
  let key ~dehydrate ~hydrate str = Some { key = str; dehydrate; hydrate }

  let persist key item =
    match key with
    | None -> ()
    | Some { key; dehydrate; _ } ->
        let storage = get_storage () in
        let obj = Js_of_ocaml.Js.Unsafe.obj [||] in
        Js_of_ocaml.Js.Unsafe.set obj "key1" 1;
        Js_of_ocaml.Js.Unsafe.set obj "key2" "abc";
        let str = Js_of_ocaml.Js._JSON##stringify obj in
        print_endline (Js_of_ocaml.Js.to_string str);
        storage##setItem (Js.string key) str

  let restore key =
    match key with
    | None -> None
    | Some { key; dehydrate; _ } ->
        let storage = get_storage () in
        let item = storage##getItem (Js.string key) in
        None
end

let dehydrate _ = "Hello world"
let hydrate _ = (Vector3.up 100.0, Vector3.zero ())
let key = PersistenceKey.key ~dehydrate ~hydrate

type cameraType = Free | Arc

type camera = {
  persistenceKey : (Vector3.t * Vector3.t) PersistenceKey.t;
  position : Vector3.t;
  rotation : Quaternion.t option;
  cameraType : cameraType;
}

let rotationEquals { rotation = rotation1; _ } { rotation = rotation2; _ } =
  match (rotation1, rotation2) with
  | None, None -> true
  | Some r1, Some r2 -> Quaternion.equals r1 r2
  | None, Some _ -> false
  | Some _, None -> false

let equals camera1 camera2 =
  Vector3.equals camera1.position camera2.position
  && rotationEquals camera1 camera2
  && camera1.cameraType = camera2.cameraType
  && PersistenceKey.equals camera1.persistenceKey camera2.persistenceKey

let persist { persistenceKey; position; rotation } =
  PersistenceKey.persist persistenceKey (position, rotation)

let camera =
  (Component.readonly ~name:"System_Camera.camera" ()
    : (Component.readonly, camera) Component.t)

let free ?(persistenceKey = PersistenceKey.none) ?rotation
    ?(position = Vector3.forward (-1.0)) () =
  { persistenceKey; position; rotation; cameraType = Free }

let arc ?(persistenceKey = PersistenceKey.none)
    ?(position = Vector3.forward (-1.0)) () =
  { persistenceKey; position; rotation = None; cameraType = Arc }

type context = { camera : camera }

let tick ~(deltaTime : float) ~(world : World.t) context = (context, world)

module Entity = struct
  let component = camera

  type t = { camera : camera }

  let camera camera =
    EntityManager.Entity.define { camera }
    |> EntityManager.Entity.withReadonlyComponent component
         (fun { camera; _ } -> camera)
end

let entity = camera