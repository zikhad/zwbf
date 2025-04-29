#!/usr/bin/env node

const translate = require('translatte');
const micromatch = require('micromatch');
const fs = require('fs-extra');
const path = require('path');

const packageJsonPath = path.join(process.cwd(), 'package.json');
const {name: projectName} = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

// Get target language from command-line arguments
const args = process.argv.slice(2);
if (args.length === 0) {
    console.error('Error: Please provide a target language code as an argument.');
    process.exit(1);
}

const targetLang = args[0]; // The first argument will be the target language
const sourceLang = 'EN'; // Source language code
const sourceDir = `${process.cwd()}/media/lua/shared/Translate/${sourceLang}`;
const targetHomeDir = `${process.cwd()}/translations/${projectName}-${targetLang.toUpperCase()}`;
const targetDir = `${targetHomeDir}/media/lua/shared/Translate/${targetLang.toUpperCase()}`;

// Ensure the target directories exists
fs.ensureDirSync(targetHomeDir);
fs.ensureDirSync(targetDir);

// Function to translate content of a file
async function translateFile(filePath, targetPath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        let targetContent = fs.existsSync(targetPath)
            ? fs.readFileSync(targetPath, 'utf8')
            : null;

        const translatedContent = await translateContent(content, targetContent);
        fs.writeFileSync(targetPath, translatedContent, 'utf8');
        console.log(`Processed: ${path.basename(filePath)} -> ${path.basename(targetPath)}`);
    } catch (err) {
        console.error(`Failed to translate ${filePath}:`, err);
    }
}

// Function to translate the content of a Lua text file
async function translateContent(sourceContent, targetContent) {
    const sourceLines = sourceContent.split('\n');
    const targetLines = targetContent ? targetContent.split('\n') : [];
    const translatedLines = [];

    const targetEntries = new Map();

    // Parse existing translations from the target file (if available)
    for (let line of targetLines) {
        const match = line.match(/(\s*.+?\s*=\s*".+?")(,?)(\s*\/\* generated \*\/)?/);
        if (match) {
            const [_, keyValue, comma, generatedComment] = match;
            const [key, value] = keyValue.split('=');
            targetEntries.set(key.trim(), {value: value.trim(), generated: !!generatedComment, comma});
        }
    }

    for (let line of sourceLines) {
        if (line.includes(`_${sourceLang} =`)) {
            line = line.replace(`_${sourceLang} =`, `_${targetLang} =`);
        }

        const match = line.match(/(\s*.+?\s*=\s*".+?"),?/);
        if (match) {
            const [fullMatch, keyValue] = match;
            const [key, value] = keyValue.split('=');
            const trimmedKey = key.trim();
            const trimmedValue = value.trim().replace(/^"|"$/g, '');

            if (targetEntries.has(trimmedKey)) {
                const {value: existingValue, generated, comma} = targetEntries.get(trimmedKey);
                const generatedComment = generated ? ' /* generated */' : '';
                const trailingComma = comma || ',';
                translatedLines.push(`	${trimmedKey} = ${existingValue}${trailingComma}${generatedComment}`);
            } else {
                try {
                    const translation = await translate(trimmedValue, {
                        from: sourceLang.toLowerCase(),
                        to: targetLang.toLowerCase()
                    });
                    const translatedValue = translation.text;
                    translatedLines.push(`	${trimmedKey} = "${translatedValue}", /* generated */`);
                    console.log(`Translated: ${trimmedKey} = "${trimmedValue}" to "${translatedValue}"`);
                } catch (e) {
                    console.error('Translation error:', e);
                    translatedLines.push(`	${trimmedKey} = "${trimmedValue}", /* generated */`);
                }
            }
        } else {
            translatedLines.push(line);
        }
    }

    return translatedLines.join('\n');
}

// Function to translate and copy the mod.info file
async function translateModInfo(targetLang, targetDir) {
    const modInfoPath = `${process.cwd()}/translations/mod.info`;
    console.log(`Processing mod.info from: ${modInfoPath}`);
    try {
        const modInfoContent = fs.readFileSync(modInfoPath, 'utf8');
        const translatedLines = [];

        const lines = modInfoContent.split('\n');
        for (let line of lines) {
            if (line.includes('=')) {
                const [key, value] = line.split('=');
                const trimmedKey = key.trim();
                let trimmedValue = value.trim();

                if (trimmedValue.includes('${lang}')) {
                    trimmedValue = trimmedValue.replace('${lang}', targetLang.toUpperCase());
                }

                if (
                    !trimmedValue.endsWith('.png') &&
                    !trimmedValue.startsWith('http') &&
                    !trimmedKey.startsWith('name') &&
                    !trimmedKey.startsWith('id') &&
                    !trimmedKey.startsWith('require')
                ) {
                    try {
                        const translation = await translate(trimmedValue, {
                            from: sourceLang.toLowerCase(),
                            to: targetLang.toLowerCase()
                        });
                        trimmedValue = translation.text;
                        console.log(`Translated: ${trimmedKey} = "${trimmedValue}" to "${translation.text}"`);
                    } catch (e) {
                        console.error('Translation error for mod.info:', e);
                    }
                }

                translatedLines.push(`${trimmedKey}=${trimmedValue}`);
            } else {
                translatedLines.push(line);
            }
        }

        const translatedModInfo = translatedLines.join('\n');
        const targetModInfoPath = path.join(targetDir, 'mod.info');
        fs.writeFileSync(targetModInfoPath, translatedModInfo, 'utf8');
        console.log(`Translated mod.info copied to: ${targetModInfoPath}`);
    } catch (err) {
        console.error('Error processing mod.info:', err);
    }
}

async function copyPoster(targetDir) {
    const posterPath = `${process.cwd()}/poster.png`;
    const logoPath = `${process.cwd()}/logo.png`;
    const targetPosterPath = path.join(targetDir, 'poster.png');
    const targetLogoPath = path.join(targetDir, 'logo.png');

    try {
        await fs.copyFile(posterPath, targetPosterPath);
        console.log(`Poster copied to: ${targetPosterPath}`);
    } catch (err) {
        console.error('Error copying poster:', err);
    }
    try {
        await fs.copyFile(logoPath, targetLogoPath);
        console.log(`Logo copied to: ${targetLogoPath}`);
    } catch (err) {
        console.error('Error copying logo:', err);
    }
}

// Main function to process all files
async function processFiles() {
    const files = fs.readdirSync(sourceDir);

    for (const file of files) {
        if (micromatch.isMatch(file, `*_${sourceLang}.txt`)) {
            const sourceFilePath = path.join(sourceDir, file);
            const targetFileName = file.replace(`_${sourceLang}.txt`, `_${targetLang}.txt`);
            const targetFilePath = path.join(targetDir, targetFileName);
            await translateFile(sourceFilePath, targetFilePath);
        }
    }

    // Translate and copy mod.info
    await translateModInfo(targetLang, targetHomeDir);
    await copyPoster(targetHomeDir);

    console.log('Translation completed!');
}

// Start the script
processFiles();
