open Util
module IntMap = (Map.Make)(Int)
type entityContext = {
  world: ReadOnlyWorld.t }
type 'state component =
  | Component:
  {
  reader: 'state -> 'component ;
  writer: 'component -> 'state -> 'state ;
  pipe: 'component Pipe.t } -> 'state component 
type 'msg handler =
  | Handler: {
  mapper: 'payload -> 'msg ;
  pipe: 'payload Pipe.t } -> 'msg handler 
type ('msg, 'state, 'effect) entityDefinition =
  {
  msgPipe: 'msg Pipe.t ;
  initialState: 'state ;
  update: ReadOnlyWorld.t -> 'msg -> 'state -> ('state * 'effect) ;
  tick: deltaTime:float -> EntityContext.t -> 'state -> ('state * 'effect) ;
  sub: 'state -> 'msg Isolinear.Sub.t option ;
  components: 'state component IntMap.t ;
  handlers: 'msg handler IntMap.t }
and ('msg, 'state, 'effect) definition =
  | Definition of ('msg, 'state, 'effect) entityDefinition 