import { test, expect, describe } from 'bun:test'
import { walkManifest, pageHtml } from '../../build.js'

describe 'walkManifest' do
	test 'rewrites the .imba service_worker and collects the JS entry' do
		const manifest = { background: { service_worker: 'background.imba' } }
		const entries = []
		const out = walkManifest(manifest, entries)
		expect(out.background.service_worker).toBe('background.js')
		expect(entries.some do(e) e.source == 'app/background.imba' and e.output == 'background.js').toBe(true)

	test 'rewrites an .imba page to .html and generates the wrapper' do
		const manifest = { action: { default_popup: 'popup/popup.imba' } }
		const entries = []
		const out = walkManifest(manifest, entries)
		expect(out.action.default_popup).toBe('popup/popup.html')
		const wrapper = entries.find do(e) e.content
		expect(wrapper.output).toBe('popup/popup.html')
		expect(wrapper.content.includes('<script type="module" src="./popup.js">')).toBe(true)

	test 'HTML wrapper points to the JS basename' do
		expect(pageHtml('options/options.js').includes('./options.js')).toBe(true)

	test 'copies plain CSS from content_scripts without modifying it' do
		const manifest = { content_scripts: [{ js: ['content/content.imba'], css: ['styles.css'] }] }
		const entries = []
		const out = walkManifest(manifest, entries)
		expect(out.content_scripts[0].css[0]).toBe('styles.css')
		expect(entries.some do(e) e.source == 'app/styles.css' and e.output == 'styles.css').toBe(true)
		expect(out.content_scripts[0].js[0]).toBe('content/content.js')

	test 'rewrites background.scripts (MV2) without manual indexing' do
		const manifest = { background: { scripts: ['background.imba', 'polyfill.js'] } }
		const entries = []
		const out = walkManifest(manifest, entries)
		expect(out.background.scripts).toEqual(['background.js', 'polyfill.js'])

	test 'leaves paths outside known keys untouched' do
		const manifest = { icons: { '128': 'assets/icon.png' } }
		const entries = []
		const out = walkManifest(manifest, entries)
		expect(out.icons['128']).toBe('assets/icon.png')
		expect(entries.length).toBe(0)
