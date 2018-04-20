configuration OctopusTentacle {
    param(
        [string]$Server = 'localhost',
        [string]$OctopusTarget,
        [string]$OctopusApiKey
    )
    Import-DscResource -ModuleName OctopusDSC

    node $Server {
        cTentacleAgent OctopusTentacle {
            Ensure                      = "Present"
            State                       = "Started"
            Name                        = "Temp"
            ApiKey                      = $OctopusApiKey
            OctopusServerUrl            = $OctopusTarget
            Environments                = "Forge.local"
            Roles                       = "MGT"
            CommunicationMode           = "Poll"
            ListenPort                  = "10933"
            ServerPort                  = "10943"
            DefaultApplicationDirectory = "C:\Octopus"
        }
    }
}