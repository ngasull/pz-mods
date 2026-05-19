function gen(scaling) {
    let canvas = document.createElement("canvas")
    canvas.width = 1
    canvas.height = 40 * scaling
    let ctx = canvas.getContext("2d")
    let radgrad = ctx.createLinearGradient(0, canvas.height, 0, 0);
    radgrad.addColorStop(0, 'rgba(255,255,255,1)');
    radgrad.addColorStop(0.25, 'rgba(255,255,255,0.65)');
    radgrad.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = radgrad;
    ctx.fillRect(0, 0, 1, canvas.height)
    let a = document.createElement("a")
    a.href = canvas.toDataURL("image/png")
    a.download = `rarity-bg-${scaling}.png`
    a.dispatchEvent(new MouseEvent("click"))
}

gen(1)
gen(2)