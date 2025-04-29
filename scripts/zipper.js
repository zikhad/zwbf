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
];

function shouldInclude(filePath) {
	return !micromatch.isMatch(filePath, EXCLUDE_PATTERNS);
}

function addFilesToArchive(archive, dirPath, baseFolder) {
	const files = fs.readdirSync(dirPath);
	files
		.filter(shouldInclude)
		.forEach(file => {
			const filePath = path.join(dirPath, file);
			const stats = fs.statSync(filePath);

			if (stats.isDirectory()) {
				archive.directory(filePath, path.join(baseFolder, file));
			} else {
				archive.file(filePath, { name: path.join(baseFolder, file) });
			}
		});
}

function addTranslationsToArchive(archive, dirPath, baseFolder) {
	const translationsDir = path.join(dirPath, 'translations');
	const files = fs.readdirSync(translationsDir);
	files.forEach(file => {
		const filePath = path.join(translationsDir, file);
		const stats = fs.statSync(filePath);
		console.log('file', file);
		console.log('filePath', filePath);
		if (stats.isDirectory()) {
			console.log(`Adding directory: ${filePath}`);
			archive.directory(filePath, path.join(`${baseFolder}`, file));
		}
	})
}

async function createZip() {
	const packageJsonPath = path.join(process.cwd(), 'package.json');
	const { name, version } = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
	const zipFileName = `${name}-${version}.zip`;
	const baseFolder = name; // Folder inside the zip

	const output = fs.createWriteStream(zipFileName);
	const archive = archiver('zip', { zlib: { level: 9 } });

	output.on('close', () => {
		console.log(`${zipFileName} has been created.`);
	});

	archive.pipe(output);

	addFilesToArchive(archive, process.cwd(), `${baseFolder}/${baseFolder}`);
	addTranslationsToArchive(archive, process.cwd(), baseFolder);

	archive.finalize();
}

createZip().catch(err => {
	console.error('Error creating zip file:', err);
});
