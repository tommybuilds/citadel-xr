let areConstructorsEqual (x : 'a) (y : 'a) =
  let r = Obj.repr x
  and s = Obj.repr y in
  if (Obj.is_int r) && (Obj.is_int s)
  then (Obj.obj r : int) = (Obj.obj s : int)
  else
    if (Obj.is_block r) && (Obj.is_block s)
    then (Obj.tag r) = (Obj.tag s)
    else false