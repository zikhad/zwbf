const fs = require('fs-extra');
const path = require('path');
const archiver = require('archiver');
const micromatch = require('micromatch');

const EXCLUDE_PATTERNS = [
	'node_modules',
	'scripts',
	'dev',
	'*.md',
	'package*',
	'.git*',
	'.nvm*',
	'*.zip',
	'*.iml',
	'*.code-workspace',
	'translations',
	'.DS_Store',
	'.idea',
];

/**
 * Checks if a file should be included in the zip archive.
 * @param {string} filePath - The path of the file to check.
 * @returns {boolean} - Returns true if the file should be included, false otherwise.
 */
function shouldInclude(filePath) {
	return !micromatch.isMatch(filePath, EXCLUDE_PATTERNS);
}

/**
 * Reads and returns package data from `package.json`.
 * @returns {{name: string, version: string}} - The package name and version.
 */
function packageData() {
	const packageJsonPath = path.join(process.cwd(), 'package.json');
	return JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
}

/**
 * Creates the main zip archive for the project, excluding translations.
 * @param {string} dirPath - The path to the directory to zip.
 */
function createMainArchive(dirPath) {
	const { name, version } = packageData();
	const files = fs.readdirSync(dirPath).filter(shouldInclude);

	const archive = archiver('zip', { zlib: { level: 9 } });
	const output = fs.createWriteStream(`${name}-${version}.zip`);

	output.on('close', () => {
		console.log(`${name}-${version}.zip has been created.`);
	});

	archive.pipe(output);

	files.forEach(file => {
		const filePath = path.join(dirPath, file);
		const stats = fs.statSync(filePath);
		if (stats.isDirectory()) {
			archive.directory(filePath, path.join(name, file));
		} else {
			archive.file(filePath, { name: path.join(name, file) });
		}
	});

	archive.finalize();
}

/**
 * Creates zip archives for each language in the translations directory.
 * @param {string} translationsDir - The path to the translations directory.
 */
function createTranslationArchives(translationsDir) {
	const { name, version } = packageData();

	fs.readdirSync(translationsDir)
		.filter(file => fs.statSync(path.join(translationsDir, file)).isDirectory())
		.forEach(folder => {
			const langMatch = folder.match(/(?<=-).+/);
			if (!langMatch) {
				console.warn(`Skipping folder "${folder}" as it does not match the expected language format.`);
				return;
			}

			const lang = langMatch[0].toLowerCase();
			const baseFolder = `${name}-${lang}`;
			const zipName = `${baseFolder}-${version}`;
			const folderPath = path.join(translationsDir, folder);

			const archive = archiver('zip', { zlib: { level: 9 } });
			const output = fs.createWriteStream(`${zipName}.zip`);

			output.on('close', () => {
				console.log(`${zipName}.zip has been created.`);
			});

			archive.pipe(output);
			archive.directory(folderPath, `${zipName}/${baseFolder}`);
			archive.finalize();
		});
}

/**
 * Creates zip files for the main directory and translations.
 * @returns {Promise<void>} - Resolves when all zip files are created.
 */
async function createZips() {
	try {
		await createMainArchive(process.cwd());
		await createTranslationArchives(path.join(process.cwd(), 'translations'));
	} catch (err) {
		console.error('Error creating zip files:', err);
	}
}

// Execute the zip creation process
createZips().then(() => {
	console.log('All zip files have been created successfully.');
});
