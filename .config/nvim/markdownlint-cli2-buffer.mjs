import { stdin } from "node:process";
import { text } from "node:stream/consumers";

const [modulePath, filename] = process.argv.slice(2);
const { main } = await import(modulePath);

process.exitCode = await main({
    argv: [filename],
    directory: process.cwd(),
    fileContents: { [filename]: await text(stdin) },
    logError: console.error,
    logMessage: console.log,
});
