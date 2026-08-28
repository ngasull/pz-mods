(async () => {
    let steps = 12
    let hsize = 15
    let thickness = 8
    let outline = 1
    let canvas = document.createElement("canvas")
    canvas.width = 2 * hsize
    canvas.height = 2 * hsize
    let ctx = canvas.getContext("2d")
    let a

    let drawSlice = (i) => {
        const r = hsize - thickness / 2 - 1
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Outline / BG
        ctx.beginPath();
        ctx.strokeStyle = '#000000dd';
        ctx.lineWidth = thickness
        ctx.arc(hsize, hsize, r, -Math.PI, -Math.PI / 2);
        ctx.stroke();

        // Ring
        ctx.beginPath();
        ctx.strokeStyle = '#ffffffcc';
        ctx.lineWidth = thickness - 2 * outline
        ctx.arc(hsize, hsize, r, -Math.PI / 2 - (i / steps) * Math.PI / 2, -Math.PI / 2);
        ctx.stroke();

        let a = document.createElement("a")
        a.href = canvas.toDataURL("image/png")
        a.download = `ring-${i}.png`
        a.dispatchEvent(new MouseEvent("click"))
    }

    for (let i = 0; i <= steps; i++) {
        drawSlice(i)
        await new Promise(resolve => setTimeout(resolve, 200))
    }

    ctx.strokeStyle = '#000000dd';
    ctx.lineWidth = 1
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.beginPath();
    ctx.moveTo(hsize, 0);
    ctx.lineTo(hsize, thickness + 1);
    ctx.stroke();
    a = document.createElement("a")
    a.href = canvas.toDataURL("image/png")
    a.download = `ring-separator.png`
    a.dispatchEvent(new MouseEvent("click"))

    let softBgSize = 64
    let softBgRadius = softBgSize / 2
    canvas = document.createElement("canvas")
    canvas.width = softBgSize
    canvas.height = softBgSize
    ctx = canvas.getContext("2d")
    let radgrad = ctx.createRadialGradient(softBgRadius, softBgRadius, 0, softBgRadius, softBgRadius, softBgRadius);
    radgrad.addColorStop(0, 'rgba(255,255,255,1)');
    // radgrad.addColorStop(0.3, 'rgba(255,255,255,0.8)');
    radgrad.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = radgrad;
    ctx.fillRect(0, 0, softBgSize, softBgSize);
    a = document.createElement("a")
    a.href = canvas.toDataURL("image/png")
    a.download = `soft-bg.png`
    a.dispatchEvent(new MouseEvent("click"))
})();
