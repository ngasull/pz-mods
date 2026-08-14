local options = PZAPI.ModOptions:create("SideBySideContainers", "Side-by-Side Containers")

return {
    options = options,
    option = {
        playerLeft = options:addTickBox("playerLeft", "Player containers on the left", false),
        lootLeft = options:addTickBox("lootLeft", "Loot containers on the left", true),
        biggerButtons = options:addTickBox("biggerButtons", "Bigger buttons (then choose size in interface tab)", false)
    },
}
