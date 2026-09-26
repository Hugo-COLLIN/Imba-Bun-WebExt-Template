import { test, expect, describe } from 'bun:test'
import { validateManifestKeys } from '../../build.js'

describe 'validateManifestKeys' do
	test 'keeps the recognized keys of the manifest' do
		const manifest = { name: 'x', version: '1.0.0', background: {} }
		const out = validateManifestKeys(manifest, 'chrome')
		expect(Object.keys(out)).toEqual(['name', 'version', 'background'])

	test 'drop npm-style keys (license, homepage)' do
		const manifest = { name: 'x', license: 'MIT', homepage: 'https://a.b' }
		const out = validateManifestKeys(manifest, 'chrome')
		expect(out.license).toBeUndefined()
		expect(out.homepage).toBeUndefined()
		expect(out.name).toBe('x')

	test 'drop unknown keys (typo, custom arbitraire)' do
		const manifest = { name: 'x', permisions: [], myCustomThing: true }
		const out = validateManifestKeys(manifest, 'firefox')
		expect(out.permisions).toBeUndefined()
		expect(out.myCustomThing).toBeUndefined()

	test 'keep homepage_url (forme manifest valide)' do
		const manifest = { name: 'x', homepage_url: 'https://a.b' }
		const out = validateManifestKeys(manifest, 'chrome')
		expect(out.homepage_url).toBe('https://a.b')
