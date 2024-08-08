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
	'*.code-workspace'
];

function shouldInclude(filePath) {
	return !micromatch.isMatch(filePath, EXCLUDE_PATTERNS);
}

function addFilesToArchive(archive, dirPath) {
	const files = fs.readdirSync(dirPath);
	files
		.filter(shouldInclude)
		.forEach(file => {
			const filePath = path.join(dirPath, file);
			const stats = fs.statSync(filePath);

			if (stats.isDirectory()) {
				archive.directory(filePath, file);
			} else {
				archive.file(filePath, { name: file });
			}
		});
}

async function createZip() {
	const packageJsonPath = path.join(process.cwd(), 'package.json');
	const { name, version } = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
	const zipFileName = `${name}-${version}.zip`;

	const output = fs.createWriteStream(zipFileName);
	const archive = archiver('zip', { zlib: { level: 9 } });

	output.on('close', () => {
		console.log(`${zipFileName} has been created.`);
	});

	archive.pipe(output);

	addFilesToArchive(archive, process.cwd());

	archive.finalize();
}

createZip().catch(err => {
	console.error('Error creating zip file:', err);
});
