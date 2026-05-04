let steps = 12
let radius = 10
let thickness = 4
let canvas = document.createElement("canvas")
canvas.width = 2 * radius
canvas.height = 2 * radius
let ctx = canvas.getContext("2d")
let a

let drawSlice = (i, name, color) => {
    ctx.strokeStyle = color;
    ctx.lineWidth = thickness
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.beginPath();
    ctx.arc(radius, radius, radius - thickness / 2 - 0.5, -Math.PI / 2 - (i / steps) * Math.PI / 2, -Math.PI / 2);
    ctx.stroke();
    let a = document.createElement("a")
    a.href = canvas.toDataURL("image/png")
    a.download = `ring-${name}-${i}.png`
    a.dispatchEvent(new MouseEvent("click"))
}

for (let i = 0; i < steps; i++) {
    setTimeout(() => drawSlice(i + 1, "good", '#00ff00cc'), i * 200)
}
for (let j = 0; j < steps; j++) {
    setTimeout(() => drawSlice(j + 1, "bad", '#ff0000cc'), (steps + j) * 200)
}

ctx.strokeStyle = '#000000dd';
ctx.lineWidth = thickness
ctx.clearRect(0, 0, canvas.width, canvas.height);
ctx.beginPath();
ctx.arc(radius, radius, radius - thickness / 2 - 0.5, 0, 2 * Math.PI);
ctx.stroke();
a = document.createElement("a")
a.href = canvas.toDataURL("image/png")
a.download = `ring-bg.png`
a.dispatchEvent(new MouseEvent("click"))

ctx.strokeStyle = '#000000dd';
ctx.lineWidth = 1
ctx.clearRect(0, 0, canvas.width, canvas.height);
ctx.beginPath();
ctx.moveTo(radius, 0);
ctx.lineTo(radius, thickness + 1);
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
