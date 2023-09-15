open Reactify_Types
module Make :
functor (ReconcilerImpl : Reconciler) ->
  React with type  node =  ReconcilerImpl.node and type  primitives = 
    ReconcilerImpl.primitives
module Utility = Utility