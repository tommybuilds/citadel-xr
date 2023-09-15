type 'a t =
  {
  currentAnimation: 'a Animation.t ;
  currentTime: float ;
  frameRate: float }
let tick ~deltaTime:(deltaTime : float)  animationPlayer =
  let frameRate = animationPlayer.frameRate in
  let newTime = animationPlayer.currentTime +. (frameRate *. deltaTime) in
  let newTime' =
    if newTime > (animationPlayer.currentAnimation).endFrame
    then
      (if (animationPlayer.currentAnimation).loop
       then
         let delta = newTime -. (animationPlayer.currentAnimation).endFrame in
         (animationPlayer.currentAnimation).startFrame +. delta
       else (animationPlayer.currentAnimation).endFrame)
    else newTime in
  ({ animationPlayer with currentTime = newTime' }, [])
let setAnimation animation animationPlayer =
  {
    animationPlayer with
    currentAnimation = animation;
    currentTime = (animation.startFrame)
  }
let frame { currentTime;_} = currentTime
let create animation =
  {
    frameRate = 60.;
    currentAnimation = animation;
    currentTime = (animation.startFrame)
  }