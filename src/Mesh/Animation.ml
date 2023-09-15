type 'a event = {
  frame: float ;
  payload: 'a }
type 'a t =
  {
  name: string ;
  loop: bool ;
  startFrame: float ;
  endFrame: float ;
  events: 'a event list }
let animation ?(loop= true)  ~startFrame  ~endFrame  (name : string) =
  { loop; name; startFrame; endFrame; events = [] }