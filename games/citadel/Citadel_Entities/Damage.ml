include
  (System_Damage.Make)(struct
                         type health = float
                         type damage = float
                         let applyDamage health damage = health -. damage
                         let isAlive health = health >= 0.
                       end)