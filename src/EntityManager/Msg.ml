open Util

let nextId = ref 0

type 'payload t = {
  typeId : int;
  friendlyName : string;
  pipe : 'payload Pipe.t;
}

let define friendlyName =
  incr nextId;
  { typeId = !nextId; friendlyName; pipe = Pipe.create () }

type instance =
  | Custom : {
      uniqueId : EntityId.t;
      msgType : int;
      pipe : 'payload Pipe.t;
      payload : 'payload;
    }
      -> instance
  | Msg : {
      uniqueId : EntityId.t;
      msgPipe : 'msg Pipe.t;
      payload : 'msg;
    }
      -> instance
