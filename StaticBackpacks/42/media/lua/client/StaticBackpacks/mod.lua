local options = PZAPI.ModOptions:create("StaticBackpacks", "Static Backpacks")

options:addDescription("Define static order for each body part")

return {
    options = options,
    option = {
        rightHand = options:addSlider("order_rightHand", "Right hand", 1, 7, 1, 1),
        leftHand = options:addSlider("order_leftHand", "Left hand", 1, 7, 1, 2),
        back = options:addSlider("order_back", "Back", 1, 7, 1, 3),
        satchel = options:addSlider("order_satchel", "Satchel", 1, 7, 1, 4),
        fannyPackFront = options:addSlider("order_fannyPackFront", "Front fanny pack", 1, 7, 1, 5),
        fannyPackBack = options:addSlider("order_fannyPackBack", "Back fanny pack", 1, 7, 1, 6),
        keyring = options:addSlider("order_keyring", "Keyring", 1, 7, 1, 7),
    },
}
