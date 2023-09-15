include
  (Rely.Make)(struct
                let config =
                  Rely.TestFrameworkConfig.initialize
                    { snapshotDir = "snapshots"; projectDir = "" }
              end)