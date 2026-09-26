import { test, expect, describe } from 'bun:test'
import { execSync } from 'child_process'
import { existsSync, readFileSync, readdirSync } from 'fs'
import { slugify } from '../../build.js'

# Integration tests: each spawns a full `bun run build.imba` run.
# Read paths from the generated manifest so the suite does not depend on where the project files live.

def readManifest
	JSON.parse(readFileSync('out/app/manifest.json', 'utf8'))

def backgroundPath
	const m = readManifest!
	m.background..service_worker or (m.background..scripts or [])[0]

# Longest line length: minified bundles are nearly one huge line.
def maxLineLength(content)
	let max = 0
	for line of content.split('\n')
		max = line.length if line.length > max
	max

describe "Intégration du build" do
	test "build dev Chrome génère manifest + background" do
		execSync('bun run build.imba', stdio: 'pipe')
		expect(existsSync('out/app/manifest.json')).toBe(true)
		expect(existsSync("out/app/{backgroundPath!}")).toBe(true)

	test "build Firefox utilise manifest V2 et background.scripts" do
		execSync('bun run build.imba --firefox', stdio: 'pipe')
		const manifest = readManifest!
		expect(manifest.manifest_version).toBe(2)
		expect(Array.isArray(manifest.background and manifest.background.scripts)).toBe(true)

	test "prod Chrome est minifié (beaucoup moins de lignes qu'en dev)" do
		execSync('bun run build.imba', stdio: 'pipe')
		const devLines = readFileSync("out/app/{backgroundPath!}", 'utf8').split('\n').length
		execSync('bun run build.imba --prod', stdio: 'pipe')
		const prodLines = readFileSync("out/app/{backgroundPath!}", 'utf8').split('\n').length
		expect(prodLines < devLines).toBe(true)

	test "Firefox n'est jamais minifié, même en prod (pas de ligne géante)" do
		execSync('bun run build.imba --firefox --prod', stdio: 'pipe')
		const longest = maxLineLength(readFileSync("out/app/{backgroundPath!}", 'utf8'))
		expect(longest <= 2000).toBe(true)

	test "--pack produit une archive nommée depuis le manifest (slug + version + browser)" do
		execSync('bun run build.imba --pack', stdio: 'pipe')
		const manifest = readManifest!
		const archiveName = "{slugify(manifest.name)}_{manifest.version}_chrome.zip"
		expect(existsSync("releases/{archiveName}")).toBe(true)

	test "tout fichier référencé par content_scripts existe dans out/app" do
		execSync('bun run build.imba', stdio: 'pipe')
		const manifest = readManifest!
		for cs of (manifest.content_scripts or [])
			for f of (cs.js or [])
				expect(existsSync("out/app/{f}")).toBe(true)
			for f of (cs.css or [])
				expect(existsSync("out/app/{f}")).toBe(true)

	test "chaque page déclarée produit son wrapper .html et son .js" do
		execSync('bun run build.imba', stdio: 'pipe')
		const manifest = readManifest!
		const page = manifest.action..default_popup or manifest.options_ui..page or manifest.options_page
		if page
			const base = page.slice(0, page.lastIndexOf('.'))
			expect(existsSync("out/app/{page}")).toBe(true)
			expect(existsSync("out/app/{base}.js")).toBe(true)
			const html = readFileSync("out/app/{page}", 'utf8')
			expect(html.includes('<script type="module" src="./')).toBe(true)

	test "les assets sont copiés si présents" do
		if existsSync('app/assets')
			execSync('bun run build.imba', stdio: 'pipe')
			expect(existsSync('out/app/assets')).toBe(true)
			expect(readdirSync('out/app/assets').length > 0).toBe(true)
