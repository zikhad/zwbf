#!/usr/bin/env node

const translate = require('translatte');
const micromatch = require('micromatch');
const fs = require('fs-extra');
const path = require('path');

// Get target language from command-line arguments
const args = process.argv.slice(2);
if (args.length === 0) {
    console.error('Error: Please provide a target language code as an argument.');
    process.exit(1);
}

const targetLang = args[0]; // The first argument will be the target language

if (!targetLang) {
  console.error('Error: Please specify the target language as the first argument.');
  console.error('Usage: node translate.js <targetLang>');
  process.exit(1);
}

const sourceLang = 'EN'; // Source language code (e.g., 'EN')
const sourceDir = `${process.cwd()}/media/lua/shared/Translate/${sourceLang}`;
const targetDir = `${process.cwd()}/media/lua/shared/Translate/${targetLang}`;

// Ensure the target directory exists
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
      targetEntries.set(key.trim(), { value: value.trim(), generated: !!generatedComment, comma });
    }
  }

  for (let line of sourceLines) {
    // Match the variable declaration line and update language code
    if (line.includes(`_${sourceLang} =`)) {
      line = line.replace(`_${sourceLang} =`, `_${targetLang} =`);
    }

    // Match lines with key-value structure
    const match = line.match(/(\s*.+?\s*=\s*".+?"),?/);
    if (match) {
      const [fullMatch, keyValue] = match;
      const [key, value] = keyValue.split('='); // Split into key and value
      const trimmedKey = key.trim();
      const trimmedValue = value.trim().replace(/^"|"$/g, ''); // Remove quotes

      if (targetEntries.has(trimmedKey)) {
        // Use existing translation and preserve the generated comment if present
        const { value: existingValue, generated, comma } = targetEntries.get(trimmedKey);
        const generatedComment = generated ? ' /* generated */' : '';
        const trailingComma = comma || ','; // Ensure the trailing comma
        translatedLines.push(`	${trimmedKey} = ${existingValue}${trailingComma}${generatedComment}`);
      } else {
        // Translate the value
        console.log('Translating:', trimmedValue);
        try {
          const translation = await translate(trimmedValue, { from: sourceLang.toLowerCase(), to: targetLang.toLowerCase() });
          const translatedValue = translation.text;

          // Append translation with trailing comma and generated comment
          translatedLines.push(`	${trimmedKey} = "${translatedValue}", /* generated */`);
        } catch (e) {
          console.error('Translation error:', e);
          translatedLines.push(`	${trimmedKey} = "${trimmedValue}", /* generated */`);
        }
      }
    } else {
      // If line doesn't match the key-value format, copy it as is
      translatedLines.push(line);
    }
  }

  return translatedLines.join('\n');
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

  console.log('Translation completed!');
}

// Start the script
processFiles();
