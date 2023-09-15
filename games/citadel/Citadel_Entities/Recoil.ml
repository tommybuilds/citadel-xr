open Babylon
type t =
  {
  horizontalSpring: Spring.t ;
  verticalSpring: Spring.t ;
  kickbackSpring: Spring.t }
let create () =
  {
    horizontalSpring = (Spring.create ());
    verticalSpring = (Spring.create ());
    kickbackSpring = (Spring.create ())
  }
let update ~deltaTime  { horizontalSpring; verticalSpring; kickbackSpring } =
  {
    horizontalSpring = (Spring.update deltaTime horizontalSpring);
    verticalSpring = (Spring.update deltaTime verticalSpring);
    kickbackSpring = (Spring.update deltaTime kickbackSpring)
  }
let kick ~horizontal:(horizontal : float)  ~vertical:(vertical : float) 
  ~kickback:(kickback : float) 
  { horizontalSpring; verticalSpring; kickbackSpring } =
  {
    horizontalSpring =
      (Spring.applyImpulse (horizontal *. (-1.)) horizontalSpring);
    verticalSpring = (Spring.applyImpulse (vertical *. (-1.)) verticalSpring);
    kickbackSpring = (Spring.applyImpulse (kickback *. (-1.)) kickbackSpring)
  }
let scale = Vector3.one
let transform { kickbackSpring; verticalSpring; horizontalSpring;_} =
  let vertical =
    Quaternion.rotateAxis (Vector3.right 1.0) (Spring.value verticalSpring) in
  let horizontal =
    Quaternion.rotateAxis (Vector3.up 1.0) (Spring.value horizontalSpring) in
  let rotation = Quaternion.multiply vertical horizontal in
  let matrix =
    Babylon.Matrix.compose ~scale ~rotation
      ~translation:(Vector3.forward (Spring.value kickbackSpring)) in
  matrix
let component recoil children =
  let matrix = transform recoil in
  let Babylon.Matrix.{ rotation; translation;_}  =
    Babylon.Matrix.decompose matrix in
  React3d.P.transform ~position:translation ~rotation children
let computeMuzzlePositionAndRotation ~position:(position : Vector3.t) 
  ~muzzleOffset:(muzzleOffset : Vector3.t) 
  ~rotation:(rotation : Quaternion.t)  recoil =
  let origRotation = rotation in
  let matrix = transform recoil in
  let Babylon.Matrix.{ rotation; translation;_}  = matrix |> Matrix.decompose in
  let muzzleOffset' =
    (muzzleOffset |> (Matrix.transformCoordinates matrix)) |>
      (fun v -> Quaternion.rotateVector v origRotation) in
  let muzzlePosition = position |> (Vector3.add muzzleOffset') in
  let rotationWithRecoil = Quaternion.multiply origRotation rotation in
  (muzzlePosition, rotationWithRecoil)