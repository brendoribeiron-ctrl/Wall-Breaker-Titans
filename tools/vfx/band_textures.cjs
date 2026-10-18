// Texturas de faixa para Beams/Trails da espada: iguais no comprimento, então os trechos da
// meia-lua emendam sem "contas" nas juntas; o perfil fica só na largura. No Beam o eixo X da
// imagem corre na LARGURA (visto no Studio em 18/10: perfil em Y virava uma conta por trecho).
// Uso: node tools/vfx/band_textures.cjs <pasta de saída>
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const W = 256, H = 64;

function crc32(buf) {
	let c, crc = 0xffffffff;
	for (let n = 0; n < buf.length; n++) {
		c = (crc ^ buf[n]) & 0xff;
		for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
		crc = (crc >>> 8) ^ c;
	}
	return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
	const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
	const td = Buffer.concat([Buffer.from(type), data]);
	const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
	return Buffer.concat([len, td, crc]);
}
function png(alphaAt) {
	const raw = Buffer.alloc((W * 4 + 1) * H);
	for (let y = 0; y < H; y++) {
		raw[y * (W * 4 + 1)] = 0;
		for (let x = 0; x < W; x++) {
			const v = (x + 0.5) / W * 2 - 1; // -1..1 na largura
			const a = Math.max(0, Math.min(1, alphaAt(v)));
			const o = y * (W * 4 + 1) + 1 + x * 4;
			raw[o] = raw[o + 1] = raw[o + 2] = 255;
			raw[o + 3] = Math.round(a * 255);
		}
	}
	const ihdr = Buffer.alloc(13);
	ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4);
	ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
	return Buffer.concat([
		Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
		chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw)), chunk("IEND", Buffer.alloc(0)),
	]);
}

const out = process.argv[2] || ".";
fs.mkdirSync(out, { recursive: true });
// halo: gaussiana larga, some antes da borda
fs.writeFileSync(path.join(out, "band_glow_x.png"), png((v) => Math.exp(-((v / 0.45) ** 2)) * (1 - v * v)));
// corpo: cheio no meio, borda macia (a borda acesa da ponta é a camada Edge)
fs.writeFileSync(path.join(out, "band_body_x.png"), png((v) => Math.min(1, 1.1 * Math.exp(-((v / 0.62) ** 2.4))) * Math.min(1, (1 - Math.abs(v)) * 5)));
// núcleo: linha fina e dura com um véu curto em volta
fs.writeFileSync(path.join(out, "band_core_x.png"), png((v) => Math.exp(-((v / 0.12) ** 2)) + 0.35 * Math.exp(-((v / 0.4) ** 2))));
console.log("ok", out);
