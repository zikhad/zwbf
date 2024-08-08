const fs = require('fs-extra');
const path = require('path');
const packageJsonPath = path.join(process.cwd(), 'package.json');
const { name, version } = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

const zipFileName = `${name}-${version}.zip`;
console.log(zipFileName);